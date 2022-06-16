// Aphelion \\

#define SERVER_ONLY

#include "UndeadCommon.as";
#include "UndeadTargeting.as";
#include "PressOldKeys.as";

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8(delay_property, 5 + XORRandom(5));

	if (!blob.exists(target_searchrad_property))
		 blob.set_f32(target_searchrad_property, 512.0f);
	
	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	CBlob@ target = this.getTarget();

	u8 delay = blob.get_u8(delay_property);
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
			
			// stay away from anything any nearby obstructions such as a tower
			//DetectForwardObstructions(blob);
			
			// should we be mad?
			// auto-enrage after some time if we cannot get to target
			const s32 timer = blob.get_s32("auto_enrage_time") - getGameTime();
			if (getDistanceBetween(target.getPosition(), blob.getPosition()) < blob.get_f32("explosive_radius") || timer < 0)
			{
				// get mad
				Enrage(blob);
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

	blob.set_u8(delay_property, delay);
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead")) return true;
	
	if (!blob.hasTag("target_until_dead"))
	{
		if (getDistanceBetween(target.getPosition(), blob.getPosition()) > blob.get_f32(target_searchrad_property))
			return true;
		else
			return !isTargetVisible(blob, target) && XORRandom(30) == 0;
	}
	
	return false;
}

void FlyAround(CBrain@ this, CBlob@ blob)
{
	// look for a target along the way :)
	FindTarget(this, blob, blob.get_f32(target_searchrad_property));

	// get our destination
	Vec2f destination = blob.get_Vec2f(destination_property);
	if (destination == Vec2f_zero || getDistanceBetween(destination, blob.getPosition()) < 128 || XORRandom(30) == 0)
	{
		NewDestination(blob);
		return;
	}

	// aim at the destination
	blob.setAimPos(destination);

	// fly to our destination
	FlyTo(blob, destination);

	// stay away from anything any nearby obstructions such as a tower
	DetectForwardObstructions(blob);

	// stay above the ground
	StayAboveGroundLevel(blob);
}

void FindTarget(CBrain@ this, CBlob@ blob, const f32&in radius)
{
	CBlob@ target = GetBestTarget(this, blob, radius);
	if (target !is null) this.SetTarget(target);
}

void FlyTo(CBlob@ blob, Vec2f&in destination)
{
	const Vec2f mypos = blob.getPosition();
	const f32 radius = blob.getRadius();
	
	blob.setKeyPressed(destination.x < mypos.x ? key_left : key_right, true);

	if (destination.y < mypos.y)
		blob.setKeyPressed(key_up, true);
		/*
	else if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(mypos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		     (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(mypos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		blob.setKeyPressed(key_up, true);
		*/
}

void DetectForwardObstructions(CBlob@ blob)
{
	if (blob.hasTag("ignore_obstructions")) return;
	
	Vec2f mypos;
	const bool obstructed = getMap().rayCastSolid(mypos, Vec2f(blob.isKeyPressed(key_right) ? mypos.x + 256.0f : // 512
		                                                                                 mypos.x - 256.0f, mypos.y));
	if (obstructed)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void StayAboveGroundLevel(CBlob@ blob)
{
	if (blob.hasTag("enraged")) return;
	
	if (getFlyHeight(blob.getPosition().x) < blob.getPosition().y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void NewDestination(CBlob@ blob)
{
	const Vec2f dim = getMap().getMapDimensions();
	s32 x = XORRandom(2) == 0 ? (dim.x / 2 + XORRandom(dim.x / 2)) :
								(dim.x / 2 - XORRandom(dim.x / 2));

	x = Maths::Clamp(x, 32, dim.x - 32); //stay within map boundaries

	// set destination
	blob.set_Vec2f(destination_property, Vec2f(x, getFlyHeight(x)));
}

const f32 getFlyHeight(const s32&in x)
{
	CMap@ map = getMap();
	return Maths::Max(0.0f, map.getLandYAtX(x / map.tilesize) * map.tilesize - 96.0f);
}

void Enrage(CBlob@ this)
{
	this.Tag("enraged");
	this.Sync("enraged", true);
}
