#include "UndeadAttackCommon.as";
#include "MakeDustParticle.as";
#include "Hitters.as";

const int COINS_ON_DEATH = 100;

void onInit(CBlob@ this)
{
	UndeadAttackVars attackVars;
	attackVars.frequency = 20;
	attackVars.map_factor = 40;
	attackVars.damage = 0.5f;
	attackVars.sound = "SkeletonAttack";
	this.set("attackVars", attackVars);
	
	if (!this.exists("skelepede_segment_amount"))
		this.set_u8("skelepede_segment_amount", 34);

	this.getAttachments().getAttachmentPointByName("PICKUP").offsetZ = -5;
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("subchattercentipede");
	sprite.SetEmitSoundPaused(false);
	sprite.SetEmitSoundVolume(0.1f);

	CShape@ shape = this.getShape();
	//shape.getConsts().net_threshold_multiplier = -1;
	shape.getConsts().mapCollisions = false;
	shape.getVars().waterDragScale = 0.0f;
	shape.SetGravityScale(0.0f);
	
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
						 u8(CBlob::map_collide_sides) |
						 u8(CBlob::map_collide_nodeath));

	this.getBrain().server_SetActive(true);

	this.Tag("skelepede");
	this.Tag("undead");
	this.Tag("winged");
	this.Tag("flesh");
	this.Tag("see_through_walls");
	this.Tag("ignore_saw");
	this.Tag("sawed"); //dont get sawed
	
	this.getCurrentScript().removeIfTag = "dead";
	
	u16[] segment_netids;
	if (isServer())
	{
		for (u8 i = 0; i < this.get_u8("skelepede_segment_amount"); i++)
		{
			CBlob@ segment = server_CreateBlobNoInit("skelepedebody");
			segment.setPosition(this.getPosition());
			segment.server_setTeamNum(this.getTeamNum());
			segment.set_netid("skelepede_head_netid", this.getNetworkID());
			segment.set_u8("skelepede_body_num", i);
			segment_netids.push_back(segment.getNetworkID());
			segment.Init();
		}
	}
	this.set("skelepede_segment_netids", segment_netids);
}

void onTick(CBlob@ this)
{
	this.setAngleDegrees(90 * (this.isFacingLeft() ? -1 : 1) - this.getVelocity().AngleDegrees());

	GoSomewhere(this);
	MoveSegments(this);
	AttackStuff(this);
}

void GoSomewhere(CBlob@ this)
{	
	CMap@ map = getMap();
    Vec2f pos = this.getPosition();
    Vec2f vel = this.getVelocity();
    CShape@ shape = this.getShape();
    CSprite@ sprite = this.getSprite();
    Vec2f destination = this.getAimPos();

    const bool inGround = map.isTileSolid(pos) || pos.y >= map.getMapDimensions().y;
    const bool wasSolidGround = map.isTileSolid(this.getOldPosition()) || this.getOldPosition().y >= map.getMapDimensions().y;
	const bool SegmentsInGround = areSegmentsInGround(this, map);
	
	//effects
    if (isClient())
    {
		//effects when surfacing
        if ((!inGround && wasSolidGround) || (inGround && !wasSolidGround) && pos.y < map.getMapDimensions().y - map.tilesize)
        {
           // sprite.PlaySound("/rocks_explode"+(1+XORRandom(2)), 0.4f, 0.8f);
            MakeDustParticle(this.getPosition(), "/Dust2.png");
        }
		
		//particle effects in front of the skelepede's path, to help players expect where it will surface
		if (inGround && getGameTime() % 3 == 0)
		{
			//fake raycasting
			Vec2f dir = this.getVelocity();
			dir.Normalize();
			const f32 step = map.tilesize * 0.5f;
			Vec2f checkPos = this.getPosition() + dir * step;
			for (u8 i = 0; i < 20; i++)
			{
				if (!map.isTileSolid(checkPos))
				{
					MakeDustParticle(checkPos, "/Dust2.png");
					break;
				}
				checkPos += dir * step;
			}
		}
		
		//set a second emitsound
		u16[] segment_netids;
		if (this.get("skelepede_segment_netids", segment_netids) && segment_netids.length > 1)
		{
			CBlob@ second_segment = getBlobByNetworkID(segment_netids[1]);
			if (second_segment !is null)
			{
				CSprite@ segment_sprite = second_segment.getSprite();
				segment_sprite.SetEmitSound("chattercentipede2");
				segment_sprite.SetEmitSoundPaused(false);
				const f32 volume = segment_sprite.getEmitSoundVolume() + (inGround ? -0.014f : 0.01f);
				segment_sprite.SetEmitSoundVolume(Maths::Clamp(volume, 0.0f, 0.4f));
			}
		}
		
		//sound when surfacing for the first time
		if (!inGround && !this.hasTag("skelepede roar"))
		{
			sprite.PlaySound("spawncentipede", 1.2f, 1.0f);
			this.Tag("skelepede roar");
		}
    }

    if (inGround || SegmentsInGround)
    {
        ShakeScreen(25, 8, pos);
        sprite.SetEmitSoundVolume(vel.Length() * 0.15f);
        shape.setDrag(0.61);
        shape.SetGravityScale(0);
    }
    else
    {
        sprite.SetEmitSoundVolume(sprite.getEmitSoundVolume() * 0.85f);
        shape.setDrag(0.042);
        shape.SetGravityScale(0.5);
    }

	//movement
	if (inGround || SegmentsInGround)
    {
        Vec2f vec(0,0);
        if (this.hasAttached())
        {
            // Move to the void
            vec = Vec2f(destination.x, map.getMapDimensions().y) - pos;
        }
        else if (vel.Length() > 3.75f && destination.y < pos.y)
        {
            // Directly target the player
            vec = destination - Vec2f(0.0f, 128.0f) - pos;
        }
        else if (vel.Length() < 1.8f && (destination - pos).Length() < this.get_f32("brain_target_rad") && Maths::Abs(destination.x - pos.x) > 16.0f)
        {
            // Move below ground
            vec = Vec2f(destination.x, map.getMapDimensions().y) - pos;
        }
        else
        {
            const float compensation_amount = 10; //40
            if (destination.x < pos.x)
            {
                if (destination.y < pos.y)
                    vec = (destination + Vec2f(-compensation_amount, -compensation_amount)) - pos;
                else
                    vec = (destination + Vec2f(-compensation_amount, compensation_amount*3)) - pos;
            }
            else
            {
                if (destination.y < pos.y)
                    vec = (destination + Vec2f(compensation_amount, -compensation_amount)) - pos;
                else
                    vec = (destination + Vec2f(compensation_amount, compensation_amount*3)) - pos;
            }
        }

        vec.Normalize();
        vec *= 0.3;
        this.setVelocity(cappedVel(vel + vec, 3.2f));
    }
}

Vec2f cappedVel(Vec2f &in velocity, f32 &in cap)
{
    return Vec2f(Maths::Clamp(velocity.x, -cap, cap), Maths::Clamp(velocity.y, -cap, cap));
}

bool areSegmentsInGround(CBlob@ this, CMap@ map, const u8 &in segmentsToCheck = 13)
{
	u16[] segment_netids;
	if (!this.get("skelepede_segment_netids", segment_netids)) return false;
	
	const u8 segmentsLength = segment_netids.length;
	for (u8 i = 0; i < segmentsLength; i++)
	{
		CBlob@ segment = getBlobByNetworkID(segment_netids[i]);
		if (segment !is null && map.isTileSolid(segment.getPosition()))
		{
			return true;
		}

		if (i > segmentsToCheck) return false;
	}
	return false;
}

void MoveSegments(CBlob@ this)
{
	u16[] segment_netids;
	if (!this.get("skelepede_segment_netids", segment_netids)) return;
	
	CBlob@ previousSegment = @this;
	
	const u8 segmentsLength = segment_netids.length;
	for (u8 i = 0; i < segmentsLength; i++)
	{
		CBlob@ segment = getBlobByNetworkID(segment_netids[i]);
		if (segment is null) continue;
		
		Vec2f pos = segment.getPosition();
		Vec2f connectorPos = previousSegment.getPosition();
		Vec2f dif = pos - connectorPos;
		
		segment.setAngleDegrees(-dif.Angle()-90.0f);
		
		const f32 segmentHeight = segment.getHeight();
		if (dif.Length() >= segmentHeight) //act like a rope
		{
			segment.setPosition(connectorPos + Vec2f(0, segmentHeight).RotateBy(-dif.Angle()-90.0f));
		}
		
		@previousSegment = segment;
	}
}

void AttackStuff(CBlob@ this)
{
	if (!isServer()) return;

	UndeadAttackVars@ attackVars;
	if (!this.get("attackVars", @attackVars)) return;

	CBlob@ carried = this.getCarriedBlob();
	if (carried is null) return;

	const u32 gameTime = getGameTime();
	if (gameTime >= attackVars.next_attack)
	{
		this.server_Hit(carried, carried.getPosition(), Vec2f_zero, attackVars.damage, attackVars.hitter, true);
		attackVars.next_attack = gameTime + attackVars.frequency;
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("skelepede") && blob.hasTag("flesh");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!isServer() || blob is null) return;
	
	//dont allow players to hide in crates
	if (blob.getName() == "crate")
	{
		CInventory@ inv = blob.getInventory();
		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			if (item.hasTag("player"))
			{
				blob.server_Die();
				break;
			}
		}
	}
	if (blob.hasTag("player") && !blob.hasTag("undead") && !blob.hasTag("dead") && !this.hasAttached())
	{
		//attach victim to mouth
		Vec2f mouth(0, -5);
		mouth.RotateBy(this.getAngleDegrees());
		mouth += this.getPosition();
		if ((mouth - point1).Length() < 5.0f)
		{
			blob.server_DetachFromAll();
			this.server_AttachTo(blob, "PICKUP");
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	Sound::Play("fallbig", this.getPosition(), 1.4f, 2.0f);
	ParticleBloodSplat(attached.getPosition(), true);
	this.getSprite().SetAnimation("attack");
}

void onDetach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().SetAnimation("default");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/SkeletonHit");
	}
	
	switch(customData)
	{
		case Hitters::ballista:     damage *= 3.5f; break;
		case Hitters::cata_boulder: damage *= 2.0f; break;
		case Hitters::bomb_arrow:   damage *= 4.2f; break;
		case Hitters::arrow:        damage *= 1.2f; break;
		case Hitters::suddengib:    damage *= 4.0f; break;
	}

	if (damage > this.getHealth() && !this.hasTag("dead"))
	{
		this.getSprite().Gib();
		server_DropCoins(worldPoint, COINS_ON_DEATH);
		onDie(this);
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		this.getSprite().PlaySound("killcentipede.ogg", 1.5f, 0.8f);
	}
	
	//kill all segments if this dies
	u16[] segment_netids;
	if (this.get("skelepede_segment_netids", segment_netids))
	{
		const u8 segmentsLength = segment_netids.length;
		for (u8 i = 0; i < segmentsLength; i++)
		{
			CBlob@ segment = getBlobByNetworkID(segment_netids[i]);
			if (segment is null) continue;
			segment.server_Die();
		}
	}
	this.Tag("dead");
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isClient() && damage > 0.0f && hitBlob.hasTag("flesh"))
	{
		this.getSprite().PlaySound("ZombieBite", 1.5f, 0.75f);
	}
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ head = makeGibParticle("Skelepede.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(25,25), 2.0f, 20, "/BodyGibFall", team);
}

/// Networking

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	u16[] segment_netids;
	if (!this.get("skelepede_segment_netids", segment_netids)) return;
	
	const u8 segmentsLength = segment_netids.length;
	stream.write_u8(segmentsLength);
	for (u8 i = 0; i < segmentsLength; i++)
	{
		stream.write_netid(segment_netids[i]);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u8 segmentsLength = 0;
	if (!stream.saferead_u8(segmentsLength))
	{
		warn("Skelepede::onReceiveCreateData - Missing segments");
		return false;
	}

	for (u8 i = 0; i < segmentsLength; i++)
	{
		u16 segmentID = 0;
		if (!stream.saferead_netid(segmentID))
		{
			warn("Skelepede::onReceiveCreateData - missing segmentID");
			return false;
		}
		
		if (i == 1)
		{
			CBlob@ second_segment = getBlobByNetworkID(segmentID);
			if (second_segment !is null)
			{
				CSprite@ segment_sprite = second_segment.getSprite();
				segment_sprite.SetEmitSound("chattercentipede2");
				segment_sprite.SetEmitSoundPaused(false);
				segment_sprite.SetEmitSoundVolume(0.0f);
			}
		}
		
		this.push("skelepede_segment_netids", segmentID);
	}

	return true;
}

//TESTING PURPOSES
void FollowCursor(CBlob@ this)
{
	CBlob@ localBlob = getBlobByName("builder");
	if (localBlob is null) return;
	
	Vec2f pos = this.getPosition();
	Vec2f aimvec = localBlob.getAimPos() - pos;
	if (aimvec.Length() >= 8.0f)
	{
		//f32 rotation = Maths::ATan2(aimvec.y, aimvec.x) * 10.0f;
		//f32 rotation = Maths::Sin(getGameTime() / 50.0f) * 50.0f;
		this.setVelocity(Vec2f(5, 0).RotateBy(-aimvec.Angle()));
	}
	else
	{
		this.setVelocity(Vec2f_zero);
	}
}
