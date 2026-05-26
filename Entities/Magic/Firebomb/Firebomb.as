#include "Hitters.as"
#include "ParticleBlast.as"

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.SetStatic(true);
	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;

	this.SetLight(true);
	this.SetLightRadius(80.0f);
	this.SetLightColor(SColor(255, 255, 150, 0));

	this.server_SetTimeToDie(3);

	this.getCurrentScript().tickFrequency = 5;
}

void onTick(CBlob@ this)
{
	Explode(this);

	this.getSprite().PlaySound("FireBlast"+(1+XORRandom(10)), 1.6f, 1.0f);
	ParticleBlastBig(this.getPosition(), 4);
	ParticleBlastSmall(this.getPosition());
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
	map.getBlobsInRadius(pos, 40.0f, @blobs);

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
	f32 damage = 1.5f;

	if (blob.hasTag("building"))
	{
		damage = 0.25f;
	}

	if (getMap().rayCastSolid(this.getPosition(), blob.getPosition()))
	{
		damage *= 0.25f;
	}

	return damage;
}

CBlob@ getOwner(CBlob@ this)
{
	if (this.exists("owner_netid"))
	{
		return getBlobByNetworkID(this.get_netid("owner_netid"));
	}
	return null;
}

