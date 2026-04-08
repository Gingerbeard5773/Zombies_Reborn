#define SERVER_ONLY

#include "UndeadTargeting.as";
#include "PressOldKeys.as";

const f32 brain_target_radius = 512.0f;

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8("brain_delay", 5 + XORRandom(5));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;

	u8 delay = blob.get_u8("brain_delay");
	delay--;
	
	if (delay == 0)
	{
		delay = 10 + XORRandom(10);
		
		// do we have a target?
		CBlob@ target = this.getTarget();
		if (target !is null)
		{
			Vec2f pos = blob.getPosition();
			Vec2f target_pos = target.getPosition();
			
			// check if the target needs to be dropped
			if (ShouldLoseTarget(blob, target))
			{
				this.SetTarget(null);
				return;
			}

			Vec2f aimvec = pos - target_pos;
			const f32 distance = aimvec.Length();
			/*aimvec.Normalize();
			aimvec *= target.getRadius() + 2.0f;
			if (getMap().rayCastSolid(pos, target_pos + aimvec))*/

			// is the target still visible?
			if (!isTargetVisible(blob, target))
			{
				this.SetTarget(null);
				
				// go to last seen position
				blob.set_Vec2f("brain_destination", target_pos);
			}

			// aim always at enemy
			blob.setAimPos(target_pos);

			// chase target
			if (distance > blob.getRadius() + 8.0f)
			{
				CMap@ map = getMap();
				
				PathTo(blob, target_pos, map);

				// scale walls and jump over small blocks
				ScaleObstacles(this, blob, target_pos, map);

				// destroy any attackable obstructions such as doors
				DestroyAttackableObstructions(this, blob, map);
			}
		}
		else
		{
			GoSomewhere(this, blob); // just walk around looking for a target
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
	
	if ((target.getPosition() - blob.getPosition()).Length() > brain_target_radius)
		return true;
	
	return false;
}

void GoSomewhere(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	SetBestTarget(this, blob, brain_target_radius);

	// get our destination
	Vec2f destination = blob.get_Vec2f("brain_destination");
	if (destination == Vec2f_zero || (destination - blob.getPosition()).Length() < 40 || XORRandom(90) == 0)
	{
		NewDestination(blob, map);
		return;
	}
	
	// aim at the destination
	blob.setAimPos(destination);

	// go to our destination
	PathTo(blob, destination, map);

	// scale walls and jump over small blocks
	ScaleObstacles(this, blob, destination, map);

	// destroy any attackable obstructions such as doors
	DestroyAttackableObstructions(this, blob, map);
}

void PathTo(CBlob@ blob, Vec2f&in destination, CMap@ map)
{
	Vec2f mypos = blob.getPosition();
	
	blob.setKeyPressed(destination.x < mypos.x ? key_left : key_right, true);

	if (destination.y + map.tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void ScaleObstacles(CBrain@ this, CBlob@ blob, Vec2f&in destination, CMap@ map)
{
	Vec2f mypos = blob.getPosition();

	// check if touching other zombies
	bool touchingOther = !blob.isOnGround() && blob.getTouchingCount() > 0;
	if (touchingOther)
	{
		touchingOther = blob.getTouchingByIndex(0).hasTag("undead");
	}

	if (blob.isOnLadder() || blob.isInWater())
	{
		blob.setKeyPressed(destination.y < mypos.y ? key_up : key_down, true);
	}
	else if (touchingOther || (blob.isOnWall() && this.getTarget() is null))
	{
		blob.setKeyPressed(key_up, true);
	}
	else
	{
		const f32 radius = blob.getRadius();
		
		if ((blob.isKeyPressed(key_right) && (map.isTileSolid(mypos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
			(blob.isKeyPressed(key_left) && (map.isTileSolid(mypos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}

void DestroyAttackableObstructions(CBrain@ this, CBlob@ blob, CMap@ map)
{
	CBlob@ obstruction = getObstructionBlob(blob, map);
	if (obstruction is null) return;

	this.SetTarget(obstruction);
}

CBlob@ getObstructionBlob(CBlob@ blob, CMap@ map)
{
	CBlob@[] blobs;
	if (!blob.getOverlapping(@blobs)) return null;

	Vec2f mypos = blob.getPosition();
	Vec2f aimvec = blob.getAimPos() - mypos;
	const f32 aimlength = aimvec.Length();
	aimvec.Normalize();

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		if (!isObstructionBlob(b)) continue;

		Vec2f bpos = b.getPosition();
		Vec2f toBlob = bpos - mypos;

		const f32 proj = toBlob.x * aimvec.x + toBlob.y * aimvec.y;
		if (proj < 0.0f || proj > aimlength) continue;

		Vec2f closest = mypos + aimvec * proj;
		const f32 dist = (bpos - closest).LengthSquared();
		const f32 radius = b.getRadius() * 2.0f;

		if (dist <= radius * radius) return b;
	}

	return null;
}

bool isObstructionBlob(CBlob@ blob)
{
	CShape@ shape = blob.getShape();
	if (!shape.isStatic() || !blob.isCollidable() || shape.getConsts().support == 0) return false;

	const string name = blob.getName();
	if (name == "bridge" || name == "trap_block") return false;

	return true;
}

void NewDestination(CBlob@ blob, CMap@ map)
{
	const Vec2f dim = map.getMapDimensions();

	Vec2f destination = blob.get_Vec2f("brain_destination");
	
	// go somewhere nearby
	if (destination != Vec2f_zero)
	{
		const s32 x = blob.getPosition().x + (XORRandom(dim.x/4) * (XORRandom(2) == 0 ? -1 : 1));
		
		if (x >= dim.x || x <= 0.0f) //stay within map boundaries
			destination = Vec2f_zero;
		else
			destination = Vec2f(x, map.getLandYAtX(x / map.tilesize) * map.tilesize);
	}

	// go somewhere near the center of the map
	if (destination == Vec2f_zero)
	{
		const s32 x = dim.x/4 + XORRandom((dim.x/4)*2);
		destination = Vec2f(x, map.getLandYAtX(x / map.tilesize) * map.tilesize);
	}
	
	// aim at destination
	blob.setAimPos(destination);

	// set destination
	blob.set_Vec2f("brain_destination", destination);
}
