// Fire ball

#include "Hitters.as"
#include "ParticleBlast.as"

void onInit(CBlob@ this)
{
	this.Tag("exploding");
	this.set_f32("explosive_radius", 24.0f);
	this.set_f32("explosive_damage", 2.0f);
	this.set_f32("map_damage_radius", 24.0f);
	this.set_f32("map_damage_ratio", 0.2f);

	this.Tag("projectile");

	this.Tag("ignore saw");
	this.Tag("sawed");//hack

	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	this.getShape().getConsts().bullet = true;

	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(3);

	this.SetLight(true);
	this.SetLightRadius(80.0f);
	this.SetLightColor(SColor(255, 255, 150, 0));

	ParticleBlastSmall(this.getPosition(), 3);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("FlareLoop.ogg");
	sprite.SetEmitSoundPaused(false);

	sprite.PlaySound("SpawnFire", 1.0f, 0.6f + blast_random.NextFloat() * 0.5f);
}

void onTick(CBlob@ this)
{
	CBlob@ target = getTarget(this);
	if (target !is null)
	{
		Vec2f dir = target.getPosition() - this.getPosition();
		dir.Normalize();

		this.AddForce(dir * 20.0f);
	}

	const f32 angle = -this.getVelocity().Angle();
	this.setAngleDegrees(angle);

	if (getGameTime() % 2 == 0)
	{
		Vec2f offset = Vec2f(-10.0f, 0.0f);
		offset.RotateBy(angle);

		Vec2f vel = this.getVelocity() + Vec2f(2.5f, 0).RotateBy(angle) * 0.9f;
		CParticle@ p = ParticleAnimated("RocketFire2.png", this.getPosition() + offset, vel, f32(XORRandom(360)), 1.0f, 3, 0.0f, false);
		if (p !is null)
		{
			p.damping = 0.85f;
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("ignore_arrow")) return false;

	if (blob is getOwner(this)) return false;

	CShape@ shape = blob.getShape();
	if (shape.isStatic() && shape.getConsts().collidable) return true;

	return blob.getTeamNum() != this.getTeamNum() && isHittable(blob);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
	{
		this.server_Die();
		return;
	}

	if (doesCollideWithBlob(this, blob))
	{
		this.server_Hit(blob, point1, this.getOldVelocity(), 1.0f, Hitters::bomb);
		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	Explode(this);

	this.getSprite().PlaySound("FireBlast"+(1+XORRandom(10)), 1.6f, 1.0f);
	ParticleBlastBig(this.getPosition(), 4);
	ParticleBlastSmall(this.getPosition());
}

CBlob@ getTarget(CBlob@ this)
{
	const f32 radius = 70.0f;
	Vec2f pos = this.getPosition();

	CBlob@[] blobs;
	getMap().getBlobsInRadius(pos, radius, @blobs);

	CBlob@ attacker = null;
	Vec2f closest_pos = Vec2f_zero;
	f32 closest_dist = radius;

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!isEnemy(this, blob)) continue;

		if (getMap().rayCastSolid(pos, blob.getPosition())) continue;

		Vec2f blob_pos = blob.getPosition();
		const f32 dist = (pos - blob_pos).Length();
		if (dist < closest_dist)
		{
			@attacker = blob;
			closest_pos = blob_pos;
			closest_dist = dist;
		}
	}

	return attacker;
}

bool isHittable(CBlob@ blob)
{
	return blob.hasTag("flesh") || blob.hasTag("undead") || blob.hasTag("skelepede") || blob.hasTag("vehicle");
}

bool isEnemy(CBlob@ this, CBlob@ blob)
{
	if (blob.getTeamNum() == this.getTeamNum()) return false;

	return blob.hasTag("player") || blob.hasTag("undead") || blob.hasTag("skelepede");
}

CBlob@ getOwner(CBlob@ this)
{
	if (this.exists("owner_netid"))
	{
		return getBlobByNetworkID(this.get_netid("owner_netid"));
	}
	return null;
}

void Explode(CBlob@ this)
{
	if (!isServer()) return;

	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const int radius = 4;
	const f32 radsq = radius * 8 * radius * 8;

	for (int x_step = -radius; x_step < radius; ++x_step)
	{
		for (int y_step = -radius; y_step < radius; ++y_step)
		{
			Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
			if (off.LengthSquared() > radsq) continue;
			
			if (XORRandom(2) == 0) continue;

			Vec2f tpos = pos + off;

			map.server_setFireWorldspace(tpos, true);
		}
	}

	CBlob@[] blobs;
	map.getBlobsInRadius(pos, 35.0f, @blobs);

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob is this) continue;

		if (blob is getOwner(this)) continue;

		const f32 damage = getDamage(this, blob);
		if (damage <= 0.0f) continue;

		Vec2f blob_pos = blob.getPosition();
		this.server_Hit(blob, blob_pos, blob_pos - pos, damage, Hitters::explosion, true);
	}
}

f32 getDamage(CBlob@ this, CBlob@ blob)
{
	f32 damage = 1.0f;

	if (blob.hasTag("building"))
	{
		damage = 0.1f;
	}

	if (getMap().rayCastSolid(this.getPosition(), blob.getPosition()))
	{
		damage *= 0.25f;
	}

	return damage;
}
