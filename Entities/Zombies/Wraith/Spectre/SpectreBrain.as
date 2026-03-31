#define SERVER_ONLY

#include "UndeadTargeting.as"
#include "PressOldKeys.as"
#include "WraithCommon.as"
#include "BrainPath.as"

const f32 brain_target_radius = 512.0f;
const u32 path_refresh_rate = 60;

class SpectrePath : BrainPath 
{
	SpectrePath(CBlob@ blob_, const u8&in flags = Path::GROUND)
	{
		super(blob_, flags);
	}

	void onTick()
	{
		if (blob.get_u32("time last pathed") + 1 != getGameTime()) return;

		if (isObstructed())
		{
			blob.getShape().SetStatic(true);
			
			if (waypoints.length > 0)
			{
				blob.setAimPos(waypoints[0]);
			}
		}
	}
	
	void CacheWaypoint(Vec2f&in waypoint)
	{
		// dont cache
	}

	bool isPathable(Vec2f&in tilePos, Vec2f&in previousPos)
	{
		for (u8 i = 0; i < 4; i++)
		{
			if (map.isTileSolid(tilePos + walkableDirections[i])) return false;
		}

		return true;
	}

	bool isObstructed()
	{
		if (waypoints.length == 0) return true;

		if (path.length <= 1) return false;

		return !BrainPath::isPathable(path[1], blob.getPosition());
	}
}

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8("brain_delay", 5 + XORRandom(5));
	
	SpectrePath pather(blob, Path::GROUND);
	blob.set("brain_path", @pather);
	
	//addOnPathDestination(blob, @onPathDestination);
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	CBlob@ target = this.getTarget();
	
	SpectrePath@ pather;
	if (!blob.get("brain_path", @pather)) return;
	
	pather.Tick();
	pather.SetSuggestedKeys();

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
			
			Vec2f pos = blob.getPosition();
			Vec2f destination = target.getPosition();
			// aim at the target
			if (!blob.getShape().isStatic() || (blob.getAimPos() - pos).Length() < 1.0f)
			{
				blob.setAimPos(destination);
			}
			
			// chase and follow target
			if (RaycastTarget(pather, blob, target) || blob.hasTag("exploding"))
			{
				//target is directly visible, go go go
				pather.EndPath();
				FlyTo(blob, destination);
			}
			else
			{
				//start pathing because we are fucking smart
				ProcessPathing(pather, blob, pos, destination);
			}

			// should we be mad?
			if ((destination - pos).Length() < blob.get_f32("explosive_radius") && !blob.hasTag("phasing"))
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

bool RaycastTarget(SpectrePath@ pather, CBlob@ blob, CBlob@ target)
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
			return hi.distance > 30.0f && !blob.isOnGround() && !pather.isPathing();
		}
		
		if (hi.blob.hasTag("door") || hi.blob.isPlatform()) return false;

		if (hi.blob is target) return true;
	}
	return false;
}

void ProcessPathing(SpectrePath@ pather, CBlob@ blob, Vec2f&in pos, Vec2f&in destination)
{
	if (getGameTime() < blob.get_u32("time last pathed") + path_refresh_rate) return;

	pather.SetPath(blob.getPosition(), destination);
	
	blob.set_u32("time last pathed", getGameTime());
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

void onRender(CSprite@ this)
{
	if ((!render_paths && g_debug == 0) || g_debug == 5) return;

	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;

	BrainPath@ pather;
	if (!blob.get("brain_path", @pather)) return;

	pather.Render();
}
