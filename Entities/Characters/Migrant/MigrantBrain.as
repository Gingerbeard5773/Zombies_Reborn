// Migrant brain

#define SERVER_ONLY

#include "/Entities/Common/Emotes/EmotesCommon.as"
#include "MigrantCommon.as"
#include "HallCommon.as"

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_bool("justgo", true);

	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run
	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	
	SetStrategy(blob, Strategy::find_teammate);
	
	//start heading to a location
	blob.set_Vec2f("brain_destination", getWaypoint(blob.getPosition()));
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	const u8 strategy = blob.get_u8("strategy");

	if ((getGameTime() + blob.getNetworkID()) % 60 == 0)
	{
		CBlob@ attacker = getAttacker(this, blob);
		if (attacker !is null)
		{
			if (!getMap().rayCastSolid(blob.getPosition(), attacker.getPosition()))
				DitchOwner(blob);
			SetStrategy(blob, Strategy::runaway);
		}

		this.SetTarget(attacker);
	}
	
	if (!blob.getShape().isStatic())
	{
		if (strategy == Strategy::runaway)
		{
			CBlob@ target = this.getTarget();
			if (blob.isAttachedToPoint("GUNNER") && target !is null && target.getHealth() > target.get_f32("gib health"))
			{
				//turret mode
				if ((blob.getAimPos() - target.getPosition()).Length() < 15 && !getMap().rayCastSolid(blob.getPosition(), target.getPosition()))
					blob.setKeyPressed(key_action1, true);
				blob.setAimPos(target.getPosition());
			}
			else if (!Runaway(this, blob, target))
			{
				if (blob.getHealth() <= blob.getInitialHealth() - blob.getInitialHealth() / 4.0f) //missing atleast a fourth of our health
					FindDormitory(blob);
				blob.set_u8("strategy", Strategy::find_teammate);
				this.SetTarget(null);
			}
		}
		else if (strategy == Strategy::find_teammate && !blob.isAttached())
		{
			GoToDestination(this, blob);
		}

		// water?
		if (blob.isInWater())
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}

void DitchOwner(CBlob@ blob)
{
	//un-owner
	CBlob@ owner = getOwner(blob);
	if (owner !is null)
	{
		detachWorker(owner, blob);
		setWorker(owner, null);
	}
	ResetWorker(blob);   //unstatic
}

void DetectObstructions(CBrain@ this, CBlob@ blob, Vec2f &in destination)
{
	u8 threshold = blob.get_u16("brain_obstruction_threshold");

	const bool obstructed = (blob.getPosition() - blob.getOldPosition()).Length() < 2.5f;
	if (obstructed)
		threshold++;
	else if (threshold > 0)
		threshold--;

	if (threshold >= 60)
	{	
		threshold = 0;
		blob.set_bool("justgo", false); //start using smart pathing
		Repath(this, destination);
	}
	
	blob.set_u16("brain_obstruction_threshold", threshold);
}

void SetStrategy(CBlob@ blob, const u8 &in strategy)
{
	blob.set_u8("strategy", strategy);
	blob.Sync("strategy", true);
}

void FindDormitory(CBlob@ blob)
{
	CBlob@[] dorms;
	if (!getBlobsByName("dorm", @dorms)) return;
	
	for (u8 i = 0; i < dorms.length; i++)
	{
		CBlob@ dorm = dorms[i];
		if (blob.getDistanceTo(dorm) < 300.0f)
		{
			blob.set_Vec2f("brain_destination", dorm.getPosition());
			break;
		}
	}
}

Vec2f getWaypoint(Vec2f &in position)
{
	Vec2f offset(8 - XORRandom(16), 0);
	if (XORRandom(2) == 0)
	{
		//choose random building
		CBlob@[] buildings;
		if (getBlobsByTag("building", @buildings))
		{
			return buildings[XORRandom(buildings.length)].getPosition() + offset;
		}
	}

	//choose closest player
	Vec2f closestPos = Vec2f_zero;
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ ply = getPlayer(i);
		if (ply is null) continue;
		
		CBlob@ plyBlob = ply.getBlob();
		if (plyBlob !is null && !plyBlob.hasTag("undead") && !plyBlob.hasTag("dead"))
		{
			if (closestPos == Vec2f_zero || (position - plyBlob.getPosition()).Length() < (position - closestPos).Length())
			{
				closestPos = plyBlob.getPosition();
			}
		}
	}

	if (closestPos == Vec2f_zero)
	{
		return position; //dont go anywhere if we dont have any options
	}

	return closestPos + offset;
}

CBlob@ getAttacker(CBrain@ this, CBlob@ blob)
{
	CBlob@ closest = null;
	CMap@ map = getMap();
	Vec2f pos = blob.getPosition();
	const f32 range = blob.isAttachedToPoint("GUNNER") ? SEEK_RANGE : ENEMY_RANGE;

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(pos, range, @blobsInRadius);

	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if ((b.hasTag("undead") || b.hasTag("animal")) && !map.rayCastSolidNoBlobs(pos, b.getPosition()))
		{
			if (closest is null || blob.getDistanceTo(b) < blob.getDistanceTo(closest))
			{
				@closest = b;
			}
		}
	}
	return closest;
}

void Repath(CBrain@ this, Vec2f &in destination)
{
	this.SetPathTo(destination, false);
}

void GoToDestination(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	Vec2f destination = blob.get_Vec2f("brain_destination");
	Vec2f pos = blob.getPosition();
	const f32 distance = (destination - blob.getPosition()).Length();
	const f32 horiz_distance = Maths::Abs(destination.x - pos.x);

	if (distance < 8.0f)
	{
		//arrived, stop pathing
		blob.set_u8("strategy", Strategy::idle);
		this.EndPath();
	}

	bool justGo = blob.get_bool("justgo");

	// check if we have a clear area to the target
	if (distance < 160.0f)
	{
		Vec2f col;
		if (!map.rayCastSolid(pos, destination, col))
		{
			justGo = true;
		}
	}

	if (justGo)
	{
		DetectObstructions(this, blob, destination);
		JustGo(this, blob, destination);
		blob.set_string("emote", "off");
	}
	else
	{
		//print("state: "+this.getStateString());
		switch (this.getState())
		{
			case CBrain::idle:
				break;
			case CBrain::searching:
				break;
			case CBrain::has_path:
			{
				//go up if path requires it, for some reason this isn't done by engine correctly? :/
				Vec2f nextPos = this.getNextPathPosition();
				if (Maths::Abs(nextPos.x - pos.x) < 16.0f && pos.y > nextPos.y)
				{
					blob.setKeyPressed(key_up, true);
				}

				if ((pos - this.getPathPositionAtIndex(this.getPathSize())).Length() > 10.0f)
					this.SetSuggestedKeys();  // set walk keys here
				else
					TrySomethingNew(this, blob, destination);
				break;
			}
			case CBrain::stuck:
			{
				TrySomethingNew(this, blob, destination);
				if (XORRandom(100) == 0)
				{
					set_emote(blob, "frown");
					if (horiz_distance > 20.0f)
					{
						if (horiz_distance < 50.0f)
							set_emote(blob, destination.y > pos.y ? "down" : "up");
						else
							set_emote(blob, destination.x > pos.x ? "right" : "left");
					}
				}
				break;
			}
			case CBrain::wrong_path:
			{
				TrySomethingNew(this, blob, destination);
				if (XORRandom(100) == 0)
				{
					if (horiz_distance < 50.0f)
						set_emote(blob, destination.y > pos.y ? "down" :"up");
					else
						set_emote(blob, destination.x > pos.x ? "right" : "left");
				}
				break;
			}
		}
	}

	// face destination
	blob.setAimPos(destination);

	JumpOverObstacles(blob);
}

void TrySomethingNew(CBrain@ this, CBlob@ blob, Vec2f &in destination)
{
	if (XORRandom(2) == 0)
	{
		blob.set_bool("justgo", true);
		this.EndPath();
	}
	else
		Repath(this, destination);
}

void JumpOverObstacles(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();
	if (!blob.isOnLadder())
		if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		        (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
}

bool JustGo(CBrain@ this, CBlob@ blob, Vec2f &in destination)
{
	Vec2f pos = blob.getPosition();
	const f32 horiz_distance = Maths::Abs(destination.x - pos.x);
	if (horiz_distance > blob.getRadius() * 0.75f)
	{
		if (destination.x < pos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (destination.y + getMap().tilesize * 0.7f < pos.y)  	 // dont hop with me
		{
			blob.setKeyPressed(key_up, true);
		}

		if (blob.isOnLadder() && destination.y > pos.y)
		{
			blob.setKeyPressed(key_down, true);
		}

		return true;
	}

	return false;
}

bool Runaway(CBrain@ this, CBlob@ blob, CBlob@ attacker)
{
	if (attacker is null || attacker.hasTag("dead")) return false;
	
	if (getMap().rayCastSolid(blob.getPosition(), attacker.getPosition())) return false;

	Vec2f pos = blob.getPosition();
	Vec2f hispos = attacker.getPosition();
	const f32 horiz_distance = Maths::Abs(hispos.x - pos.x);

	if (hispos.x > pos.x)
	{
		blob.setKeyPressed(key_left, true);
		blob.setAimPos(pos + Vec2f(-10.0f, 0.0f));
	}
	else
	{
		blob.setKeyPressed(key_right, true);
		blob.setAimPos(pos + Vec2f(10.0f, 0.0f));
	}

	if (hispos.y - getMap().tilesize > pos.y)
	{
		blob.setKeyPressed(key_up, true);
	}

	JumpOverObstacles(blob);

	//out of sight?
	if ((pos - hispos).getLength() > 200.0f)
	{
		return false;
	}

	return true;
}
