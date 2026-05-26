#include "Hitters.as"
#include "ParticleBlast.as"

const int LIFETIME = 4;
const int EXTENDED_LIFETIME = 6;
const f32 SEARCH_RADIUS = 128.0f;
const f32 HOMING_STRENGTH = 2.0f;
const int HOMING_DELAY = 15;

void onInit(CBlob@ this)
{
	this.Tag("projectile");

	this.Tag("ignore saw");
	this.Tag("sawed");//hack

	//dont collide with edge of the map
	this.SetMapEdgeFlags(u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath));

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("FlareLoop.ogg");
	sprite.SetEmitSoundVolume(0.6f);
	sprite.SetEmitSoundSpeed(0.85f);
	sprite.SetEmitSoundPaused(false);
	sprite.SetZ(100.0f);

	this.addCommandID("client_explode");

	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 255, 150, 0));
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	Vec2f pos = this.getPosition();

	const f32 angle = -this.getVelocity().Angle();
	this.setAngleDegrees(angle);

	const u32 time_alive = this.getTickSinceCreated();
	const u16 target_netid = this.get_netid("missile_target");

	if (time_alive > HOMING_DELAY)
	{
		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target !is null)
		{
			// follow the target
			Vec2f targetNorm = target.getPosition() - pos;
			targetNorm.Normalize();

			this.AddForce(targetNorm * HOMING_STRENGTH);
		}
		else 
		{
			// look for a valid target
			f32 best_dist = 99999999;
			u16 best_netid = 0;

			CBlob@[] blobs;
			getMap().getBlobsInRadius(pos, SEARCH_RADIUS, @blobs);
			for (int i = 0; i < blobs.length; ++i)
			{
				CBlob@ other = blobs[i];
				if (other is this) continue;

				if (!isEnemy(this, other)) continue;

				const f32 dist = (other.getPosition() - pos).getLength();
				if (dist < best_dist)
				{
					best_netid = other.getNetworkID();
					best_dist = dist;
				}
			}

			if (best_netid > 0)
			{
				this.set_netid("missile_target", best_netid);
			}
		}
	}

	if (target_netid > 0 && time_alive > (LIFETIME + EXTENDED_LIFETIME)*30)
	{
		server_Explode(this);
	}
	else if (target_netid == 0 && time_alive > LIFETIME*30)
	{
		server_Explode(this);
	}

	// random motion
	if (time_alive % 4 == 0)
	{
		Random rand(this.getNetworkID() * 33 + time_alive);

		const f32 random_angle = rand.NextFloat() * 360.0f * Maths::Pi / 180.0f;
		Vec2f random_vel(Maths::Cos(random_angle), Maths::Sin(random_angle));

		const f32 magnitude = (rand.NextFloat() * 32.0f + 32.0f) * 0.0078125f + 0.75f;
		random_vel *= magnitude * 4.0f;

		this.AddForce(random_vel);
	}

	this.AddForce(Vec2f(1, 0).RotateBy(angle) * 0.25f);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!isServer()) return;

	if (solid && this.getTickSinceCreated() > HOMING_DELAY)
	{
		server_Explode(this);
		return;
	}

	if (blob !is null && isEnemy(this, blob))
	{
		this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.5f, Hitters::explosion, true);
		server_Explode(this);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	if (target.getTeamNum() == this.getTeamNum()) return false;

	return target.hasTag("player") || target.hasTag("undead") || target.hasTag("skelepede");
}

CBlob@ getOwner(CBlob@ this)
{
	if (this.exists("owner_netid"))
	{
		return getBlobByNetworkID(this.get_netid("owner_netid"));
	}
	return null;
}

void server_Explode(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, 24.0f, @blobs);

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob is getOwner(this)) continue;

		Vec2f blob_pos = blob.getPosition();
		if (map.rayCastSolid(pos, blob_pos)) continue;

		this.server_Hit(blob, blob_pos, blob_pos - pos, getDamage(this, blob), Hitters::explosion, false);
	}

	this.server_SetTimeToDie(3);

	SetBlobDeactivated(this);

	this.SendCommand(this.getCommandID("client_explode"));
}

f32 getDamage(CBlob@ this, CBlob@ blob)
{
	f32 damage = 1.0f;

	if (blob.hasTag("building"))
	{
		damage = 0.1f;
	}

	return damage;
}

void SetBlobDeactivated(CBlob@ this)
{
	this.SetVisible(false);
	this.SetLight(false);

	CShape@ shape = this.getShape();
	shape.server_SetActive(false);
	shape.doTickScripts = false;
	this.doTickScripts = false;

	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_explode") && isClient())
	{
		ParticleBlast(this.getPosition(), 5);
		this.getSprite().PlaySound("GenericExplosion1.ogg", 0.8f, 0.8f + XORRandom(10) / 10.0f);
		this.getSprite().SetEmitSoundPaused(true);

		SetBlobDeactivated(this);
	}
}
