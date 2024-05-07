#define SERVER_ONLY

#include "UndeadTargeting.as";
#include "PressOldKeys.as";

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.exists("brain_target_rad"))
		blob.set_f32("brain_target_rad", 220.0f);

	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

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
			SetBestTarget(this, blob, blob.get_f32("brain_target_rad"));

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
		
	if ((target.getPosition() - blob.getPosition()).Length() > blob.get_f32("brain_target_rad"))
		return true;
	
	return false;
}
