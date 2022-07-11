#define SERVER_ONLY

#include "UndeadTargeting.as";
#include "PressOldKeys.as";

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8("brain_delay", 5 + XORRandom(5));

	if (!blob.exists("brain_target_rad"))
		 blob.set_f32("brain_target_rad", 512.0f);
	
	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
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
			
			// aim at the target
			blob.setAimPos(target.getPosition());
			
			// chase target
			FlyTo(blob, target.getPosition());
			
			// should we be mad?
			// auto-enrage after some time if we cannot get to target
			const s32 timer = blob.get_s32("auto_enrage_time") - getGameTime();
			if ((target.getPosition() - blob.getPosition()).Length() < blob.get_f32("explosive_radius") || timer < 0)
			{
				// get mad
				blob.Tag("enraged");
				blob.Sync("enraged", true);
			}
		}
		else
		{
			FlyAround(this, blob); // just fly around looking for a target
		}
	}
	else
	{
		PressOldKeys(blob);
	}

	blob.set_u8("brain_delay", delay);
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead"))
		return true;
	
	if ((target.getPosition() - blob.getPosition()).Length() > blob.get_f32("brain_target_rad"))
		return true;
	
	return !isTargetVisible(blob, target) && XORRandom(30) == 0;
}

void FlyAround(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	SetBestTarget(this, blob, blob.get_f32("brain_target_rad"));

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
	if (blob.hasTag("enraged")) return;
	
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
