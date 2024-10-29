#define SERVER_ONLY

#include "UndeadTargeting.as";
#include "PressOldKeys.as";
#include "WraithCommon.as";

const f32 brain_target_radius = 512.0f;

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8("brain_delay", 5 + XORRandom(5));
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	CBlob@ target = this.getTarget();

	u8 delay = blob.get_u8("brain_delay");
	delay--;

	if (delay == 0)
	{
		delay = 5 + XORRandom(10);

		// do we have a target?
		if (target !is null)
		{
			if (ShouldLoseTarget(blob, target))
			{
				this.SetTarget(null);
				return;
			}
			
			Vec2f destination = target.getPosition();
			
			// aim at the target
			blob.setAimPos(destination);

			Vec2f pos = blob.getPosition();
			
			// chase and follow target
			if (RaycastTarget(this, blob, target) || blob.hasTag("exploding"))
			{
				//target is directly visible, go go go
				this.EndPath();
				FlyTo(blob, destination);
			}
			else
			{
				//start pathing because we are fucking smart
				ProcessPathing(this, blob, pos, destination);
			}

			// should we be mad?
			// auto-enrage after some time if we cannot get to target
			const s32 timer = blob.get_s32("auto_enrage_time") - getGameTime();
			if (((destination - pos).Length() < blob.get_f32("explosive_radius") || timer < 0))
			{
				server_SetEnraged(blob, true, false, false);
			}
		}
		else
		{
			this.EndPath();
			FlyAround(this, blob); // just fly around looking for a target
		}
	}
	else
	{
		PressOldKeys(blob);
	}

	blob.set_u8("brain_delay", delay);
}

bool RaycastTarget(CBrain@ this, CBlob@ blob, CBlob@ target)
{
	Vec2f pos = blob.getPosition();
	Vec2f ray = target.getPosition() - pos;

	HitInfo@[] hitInfos;
	getMap().getHitInfosFromRay(pos, -ray.getAngle(), ray.Length(), blob, hitInfos);
	
	for (int i = 0; i < hitInfos.length; i++)
	{
		HitInfo@ hi = hitInfos[i];
		if (hi.blob is null)
		{
			if (hi.distance > 30.0f && !blob.isOnGround() && this.getPathSize() == 0) 
				return true;
			return false;
		}

		if (hi.blob is target) return true;
		
		if (hi.blob.isCollidable() && hi.blob.getShape().isStatic() && blob.doesCollideWithBlob(hi.blob))
		{
			this.SetTarget(hi.blob);
			return true;
		}
	}
	return false;
}

void ProcessPathing(CBrain@ this, CBlob@ blob, Vec2f&in pos, Vec2f&in destination)
{
	switch (this.getState())
	{
		case CBrain::searching:
			break;
		case CBrain::has_path:
		{
			//go up if path requires it, for some reason this isn't done by engine correctly? :/
			Vec2f nextPos = this.getNextPathPosition();
			if (pos.y > nextPos.y)
			{
				blob.setKeyPressed(key_up, true);
			}

			this.SetSuggestedKeys();
				
			if ((pos - this.getPathPositionAtIndex(this.getPathSize())).Length() < 24.0f)
			{
				this.SetPathTo(destination, true);
			}
			break;
		}
		case CBrain::idle:
		case CBrain::stuck:
		case CBrain::wrong_path:
		{
			if (XORRandom(2) == 0)
			{
				//just try random directions to see if we can find a better path (hacky)
				Vec2f random_offset(XORRandom(200) - 100, XORRandom(300) - 150);
				this.SetPathTo(pos + random_offset, true);
			}
			else //attempt direct path again
			{
				this.SetPathTo(destination, true);
			}
			break;
		}
	}
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead"))
		return true;
	
	if ((target.getPosition() - blob.getPosition()).Length() > brain_target_radius)
		return true;
	
	return false;
}

void FlyAround(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	SetBestTarget(this, blob, brain_target_radius);

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

void FlyTo(CBlob@ blob, Vec2f&in destination)
{
	Vec2f mypos = blob.getPosition();
	
	blob.setKeyPressed(destination.x < mypos.x ? key_left : key_right, true);

	if (destination.y < mypos.y)
		blob.setKeyPressed(key_up, true);
}

void DetectForwardObstructions(CBlob@ blob, CMap@ map)
{
	Vec2f mypos = blob.getPosition();
	const bool obstructed = map.rayCastSolidNoBlobs(mypos, Vec2f(blob.isKeyPressed(key_right) ? mypos.x + 256.0f : // 512
		                                                                                 mypos.x - 256.0f, mypos.y));
	if (obstructed)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void StayAboveGroundLevel(CBlob@ blob, CMap@ map)
{
	if (blob.hasTag("exploding")) return;
	
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
	return Maths::Max(0.0f, map.getLandYAtX(x / map.tilesize) * map.tilesize - 96.0f);
}
