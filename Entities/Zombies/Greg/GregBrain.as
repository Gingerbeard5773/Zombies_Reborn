#define SERVER_ONLY

#include "UndeadTargeting.as"
#include "PressOldKeys.as"
#include "GetSurvivors.as"
#include "UndeadTeam.as"
#include "Zombie_AchievementsCommon.as"

const f32 brain_target_radius = 512.0f;

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8("brain_delay", 5 + XORRandom(5));
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	u8 delay = blob.get_u8("brain_delay") - 1;

	if (delay > 0)
	{
		PressOldKeys(blob);
		blob.set_u8("brain_delay", delay);
		return;
	}

	delay = 5 + XORRandom(10);
	blob.set_u8("brain_delay", delay);

	// do we have a target?
	CBlob@ target = this.getTarget();
	if (target is null)
	{
		FlyAround(this, blob); // just fly around looking for a target
		return;
	}

	// need to pick the target up
	CBlob@ carried = blob.getCarriedBlob();
	if (carried is null || carried !is target)
	{
		// check if the target needs to be abandoned
		if (ShouldLoseTarget(blob, target))
		{
			DetachTarget(this, blob, carried);
			return;
		}
		
		// chase target
		FlyTo(blob, target.getPosition());

		// aim at the target
		blob.setAimPos(target.getPosition());

		return;
	}

	if (carried.hasTag("undead"))
	{
		TaxiUndead(this, blob, carried);
		return;
	}

	const f32 drop_height = 400.0f;
	Vec2f pos = blob.getPosition();
	Vec2f below = pos + Vec2f(0, drop_height);

	if (pos.y < 30 && !getMap().rayCastSolid(pos, below))
	{
		// bye bye!
		CPlayer@ player = carried.getPlayer();
		if (player !is null)
		{
			Achievement::server_Unlock(Achievement::SkyDiving, player);
		}
		DetachTarget(this, blob, carried);
	}
	else
	{
		FlyTo(blob, Vec2f(pos.x, -drop_height));
	}
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead") || target.isAttached())
		return true;
		
	if ((target.getPosition() - blob.getPosition()).Length() > brain_target_radius)
		return true;
	
	return !isTargetVisible(blob, target);
}

void FlyAround(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	FindTarget(this, blob, map);

	// get our destination
	Vec2f destination = blob.get_Vec2f("brain_destination");
	if (destination == Vec2f_zero || (destination - blob.getPosition()).Length() < 128 || XORRandom(30) == 0)
	{
		NewDestination(blob, map);
		return;
	}

	// aim at the destination
	blob.setAimPos(destination);

	// fly to our destination
	FlyTo(blob, destination);

	// stay away from anything any nearby obstructions such as a tower
	DetectForwardObstructions(blob, map);

	// stay above the ground
	StayAboveGroundLevel(blob, map);
}

void TaxiUndead(CBrain@ this, CBlob@ blob, CBlob@ carried)
{
	CBlob@ player_target = getBlobByNetworkID(blob.get_netid("brain_player_target"));
	if (player_target is null)
	{
		DetachTarget(this, blob, carried);
		return;
	}

	const Vec2f target_pos = player_target.getPosition();

	if (getXBetween(target_pos, blob.getPosition()) < 50.0f)
	{
		carried.set_Vec2f("brain_destination", target_pos); //tell the zombie where to look
		DetachTarget(this, blob, carried);
	}
	else
	{
		CMap@ map = getMap();

		// aim at the destination
		blob.setAimPos(target_pos);

		// fly to our destination
		FlyTo(blob, Vec2f(target_pos.x, getFlyHeight(target_pos.x, map)));

		// stay away from anything any nearby obstructions such as a tower
		DetectForwardObstructions(blob, map);

		// stay above the ground
		StayAboveGroundLevel(blob, map);
	}
}

void FindTarget(CBrain@ this, CBlob@ blob, CMap@ map)
{
	CBlob@ player_target = getBlobByNetworkID(blob.get_netid("brain_player_target"));
	if (player_target is null)
	{
		SetPlayerTarget(blob);
	}

	Vec2f pos = blob.getPosition();

	CBlob@[] blobs;
	map.getBlobsInRadius(pos, brain_target_radius, @blobs);

	CBlob@[] taxi_blobs;
	CBlob@ best_target;
	f32 closest_distance = 999999.9f;

	for (int i = 0; i < blobs.length; ++i)
	{
		CBlob@ candidate = blobs[i];

		const f32 distance = (candidate.getPosition() - pos).Length();
		if (distance >= closest_distance) continue;

		if (blob.isAttached() || blob.hasTag("dead")) continue;

		if (candidate.hasTag("undead"))
		{
			if (isInNeedOfTaxi(candidate, player_target))
			{
				taxi_blobs.push_back(candidate);
			}
		}
		else if (canTarget(blob, candidate))
		{
			@best_target = candidate;
			closest_distance = distance;
			break;
		}
	}

	if (taxi_blobs.length > 0 && best_target is null)
	{
		@best_target = taxi_blobs[XORRandom(taxi_blobs.length)];
	}

	if (best_target !is null)
	{
		this.SetTarget(best_target);
	}
}

bool canTarget(CBlob@ blob, CBlob@ candidate)
{
	if (!candidate.hasTag("player") || isUndeadTeam(candidate)) return false;

	if (!isTargetVisible(blob, candidate)) return false;

	return true;
}

bool isInNeedOfTaxi(CBlob@ candidate, CBlob@ player_target)
{
	if (player_target is null) return false;

	if (candidate.hasTag("winged") || !isUndeadTeam(candidate)) return false;

	CBrain@ brain = candidate.getBrain();
	if (brain is null) return false;

	CBlob@ target = brain.getTarget();
	return target is null && getXBetween(candidate.getPosition(), player_target.getPosition()) > 210.0f;
}

void FlyTo(CBlob@ blob, Vec2f&in destination)
{
	Vec2f pos = blob.getPosition();
	const f32 radius = blob.getRadius();

	blob.setKeyPressed(destination.x < pos.x ? key_left : key_right, true);

	if (destination.y < pos.y)
		blob.setKeyPressed(key_up, true);
	else if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		     (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		blob.setKeyPressed(key_up, true);
}

void DetectForwardObstructions(CBlob@ blob, CMap@ map)
{
	Vec2f pos = blob.getPosition();
	Vec2f end_pos = pos + Vec2f(blob.isKeyPressed(key_right) ? 256.0f : 256.0f, 0);

	if (map.rayCastSolid(pos, end_pos))
	{
		blob.setKeyPressed(key_up, true);
	}
}

void StayAboveGroundLevel(CBlob@ blob, CMap@ map)
{
	if (getFlyHeight(blob.getPosition().x, map) < blob.getPosition().y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void NewDestination(CBlob@ blob, CMap@ map)
{
	const Vec2f dim = map.getMapDimensions();
	
	s32 x = XORRandom(2) == 0 ? (dim.x / 2 + XORRandom(dim.x / 2)) :
								(dim.x / 2 - XORRandom(dim.x / 2));
	
	x = Maths::Clamp(x, 32, dim.x - 32); //stay within map boundaries

	// set destination
	blob.set_Vec2f("brain_destination", Vec2f(x, getFlyHeight(x, map)));
}

const f32 getFlyHeight(const s32&in x, CMap@ map)
{
	return map.getLandYAtX(x / map.tilesize) * map.tilesize - 128.0f;
}

const f32 getXBetween(Vec2f&in point1, Vec2f&in point2)
{
	return Maths::Abs(point1.x - point2.x);
}

void DetachTarget(CBrain@ this, CBlob@ blob, CBlob@ carried)
{
	if (carried !is null)
	{
		carried.server_DetachFrom(blob);
	}

	this.SetTarget(null);
}

void SetPlayerTarget(CBlob@ blob)
{
	CBlob@[] survivors = getSurvivors();
	if (survivors.length <= 0) return;

	const u16 netid = survivors[XORRandom(survivors.length)].getNetworkID();
	blob.set_netid("brain_player_target", netid);
}
