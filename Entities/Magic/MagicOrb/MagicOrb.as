// Magic Orb

#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("exploding");
	this.set_f32("explosive_radius", 12.0f);
	this.set_f32("explosive_damage", 4.0f);
	this.set_f32("map_damage_radius", 0.0f);
	this.set_f32("map_damage_ratio", 0.0f);

	this.Tag("projectile");

	this.Tag("ignore saw");
	this.Tag("sawed");//hack

	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	this.getShape().getConsts().bullet = true;

	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(3);

	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 211, 121, 224));

	this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
	this.getSprite().PlaySound("OrbFireSound.ogg");
	this.getSprite().SetZ(1000.0f);
}

void onTick(CBlob@ this)
{
	CBlob@ target = getTarget(this);
	if (target !is null)
	{
		Vec2f dir = target.getPosition() - this.getPosition();
		dir.Normalize();

		this.AddForce(dir * 0.25f);
	}

	if (getGameTime() % 2 == 0)
	{
		OrbParticles(this.getPosition());
	}
}

void OrbParticles(Vec2f pos)
{
	if (!isClient()) return;

	SColor col(255, 10 + XORRandom(70), 140, 255);
	CParticle@ p = ParticlePixelUnlimited(pos, Vec2f_zero, col, true);
	if (p is null) return;

	p.collides = false;
	p.timeout = 10 + XORRandom(20);
	p.gravity = Vec2f_zero;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("ignore_arrow")) return false;

	CShape@ shape = blob.getShape();
	if (shape.isStatic() && shape.getConsts().collidable) return true;

	return blob.getTeamNum() != this.getTeamNum() && isHittable(blob);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null) return;

	if (isHittable(blob) && blob.getTeamNum() != this.getTeamNum())
	{
		this.server_Hit(blob, point1, this.getVelocity(), 1.0f, Hitters::bomb);
		this.server_Die();
	}
}

CBlob@ getTarget(CBlob@ this)
{
	const f32 radius = 70.0f;
	Vec2f pos = this.getPosition();

	CBlob@[] blobsInRadius;
	getMap().getBlobsInRadius(pos, radius, @blobsInRadius);

	CBlob@ attacker = null;
	Vec2f closest_pos = Vec2f_zero;
	f32 closest_dist = radius;

	for (u16 i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (!isEnemy(this, b)) continue;

		if (getMap().rayCastSolid(pos, b.getPosition())) continue;

		Vec2f b_pos = b.getPosition();
		const f32 dist = (pos - b_pos).Length();
		if (dist < closest_dist)
		{
			@attacker = b;
			closest_pos = b_pos;
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
