#define SERVER_ONLY

#include "PressOldKeys.as";

const f32 brain_target_radius = 220.0f;

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if ((getGameTime() + blob.getNetworkID()) % 5 != 0) return;

	Vec2f destination;
	CBlob@ target = this.getTarget();
	if (target !is null)
	{
		destination = target.getPosition();
		// check if the target needs to be dropped
		if (ShouldLoseTarget(blob, target) || XORRandom(70) == 0)
		{
			this.SetTarget(null);
			return;
		}
	}
	else
	{
		if (XORRandom(10) == 0)
			SetBestTargetNoMigrants(this, blob, brain_target_radius);

		destination = blob.get_Vec2f("brain_destination");
		if (destination == Vec2f_zero || (destination - blob.getPosition()).Length() < 60 || XORRandom(70) == 0)
		{
			NewDestination(blob, getMap());
			return;
		}
	}

	blob.setAimPos(destination);
}

void NewDestination(CBlob@ blob, CMap@ map)
{
	const Vec2f dim = map.getMapDimensions();

	Vec2f destination = blob.get_Vec2f("brain_destination");
	
	// go somewhere
	const s32 x = blob.getPosition().x + (XORRandom(dim.x/4) * (XORRandom(2) == 0 ? -1 : 1));
	
	if (x >= dim.x || x <= 0.0f) //stay within map boundaries
		destination = Vec2f_zero;
	else
		destination = Vec2f(x, (map.getLandYAtX(x / map.tilesize) * map.tilesize) - XORRandom(140) + 40);

	// set destination
	blob.set_Vec2f("brain_destination", destination);
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead") || target.isAttachedTo(blob))
		return true;
		
	if ((target.getPosition() - blob.getPosition()).Length() > brain_target_radius)
		return true;
	
	return false;
}

void SetBestTargetNoMigrants(CBrain@ this, CBlob@ blob, const f32&in radius)
{
	u16[]@ targetBlobs;
	if (!getRules().get("target netids", @targetBlobs)) return;

	const Vec2f pos = blob.getPosition();

	CBlob@ target;
	f32 closest_dist = 999999.9f;
	
	const u16 blobsLength = targetBlobs.length;
	for (u16 i = 0; i < blobsLength; ++i)
	{
		CBlob@ candidate = getBlobByNetworkID(targetBlobs[i]);
		if (candidate is null || candidate.hasTag("dead") || candidate.hasTag("migrant")) continue;

		const f32 dist = (candidate.getPosition() - pos).Length();
		if (dist < radius && dist < closest_dist)
		{
			@target = candidate;
			closest_dist = dist;
		}
	}
	
	if (target !is null)
	{
		this.SetTarget(target);
	}
}
