#include "UndeadAttackCommon.as";
#include "MakeDustParticle.as";

const int COINS_ON_DEATH = 20;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.getConsts().net_threshold_multiplier = -1;
	//shape.SetGravityScale(0.0f);
	shape.SetStatic(true);
	
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
						 u8(CBlob::map_collide_sides) |
						 u8(CBlob::map_collide_nodeath));

	this.Tag("skelepede");
	this.Tag("winged");
	this.Tag("flesh");
	this.Tag("builder always hit");
	
	AssignBodySize(this); //localhost
	
	this.getCurrentScript().removeIfTag = "dead";
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	AssignBodySize(this);
	return true;
}

void AssignBodySize(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CBlob@ head = getBlobByNetworkID(this.get_netid("skelepede_head_netid"));
	const u8 total_segments = head !is null ? head.get_u8("skelepede_segment_amount") : 34;

	//set body sprite depending on where we are in the chain
	const u8 body_num = this.get_u8("skelepede_body_num");
	if (body_num == 3 || body_num == 4 ||
		(body_num >= total_segments - 6 && body_num < total_segments - 3))
	{
		sprite.SetAnimation("large");
	}
	else if (body_num == 1 || body_num == 2 ||
			 body_num == total_segments - 3 || body_num == total_segments - 2)
	{
		sprite.SetAnimation("medium");
	}
	else if (body_num == total_segments - 1)
	{
		sprite.SetAnimation("small");
	}
}

void onTick(CBlob@ this)
{
	if ((getGameTime() + this.getNetworkID()) % 5 != 0) return;

	CMap@ map = getMap();
	if (!map.isTileSolid(this.getPosition()) && map.isTileSolid(this.getOldPosition()))
	{
		MakeDustParticle(this.getPosition(), "/DustSmall.png");
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.hasTag("flesh");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("undead")) return 0.0f;

	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/SkeletonHit");
		makeGibParticle("GenericGibs",
					                this.getPosition(), getRandomVelocity(-90, (Maths::Min(Maths::Max(0.3f, damage), 0.75f) * 2.0f) , 270),
					                5, 2 + XORRandom(2), Vec2f(8, 8),
					                1.0f, 0, "", 0);
	}
	
	if (isServer())
	{
		//damage is sent to skelepede's head
		CBlob@ head = getBlobByNetworkID(this.get_netid("skelepede_head_netid"));
		if (head !is null)
		{
			hitterBlob.server_Hit(head, worldPoint, velocity, damage, customData, true);
		}
	}

	return 0.0f;
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		this.getSprite().PlaySound("/SkeletonBreak1");
		this.getSprite().Gib();
	}
	
	if (isServer())
	{
		//kill skelepede head if this dies somehow
		CBlob@ head = getBlobByNetworkID(this.get_netid("skelepede_head_netid"));
		if (head !is null)
		{
			head.server_Die();
		}
	}
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) return;
	
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	const f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	vel += getRandomVelocity(90, hp , 80);
	const u8 team = blob.getTeamNum();
	const string name = this.animation.name;
	const u8 row = name == "medium" || name == "small" ? 2 : 1;
	CParticle@ body = makeGibParticle("Skelepede.png", pos, vel, 0, row, Vec2f(25,25), 2.0f, 20, "/BodyGibFall", team);
}
