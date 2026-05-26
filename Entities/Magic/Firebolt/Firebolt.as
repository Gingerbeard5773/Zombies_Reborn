// Fire bolt

#include "Hitters.as"
#include "ParticleMagic.as"

void onInit(CBlob@ this)
{
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

	this.getSprite().PlaySound("FireBlast11", 1.0f, 1.0f);
}

void onTick(CBlob@ this)
{
	ParticleMagic(this.getPosition(), "RocketFire3.png");
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

	this.getSprite().PlaySound("FireBlast11", 1.0f, 1.0f);
	
	for (u8 i = 0; i < 10; i++)
	{
		CParticle@ p = ParticleMagic(this.getPosition(), "RocketFire3.png");
		if (p is null) continue;

		p.velocity *= 2.5f;
	}
}

bool isHittable(CBlob@ blob)
{
	return blob.hasTag("flesh") || blob.hasTag("undead") || blob.hasTag("skelepede") || blob.hasTag("vehicle");
}

void Explode(CBlob@ this)
{
	if (!isServer()) return;

	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const int radius = 2;
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
}
