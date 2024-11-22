#include "Hitters.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(20);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	this.Tag("projectile");

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	this.sendonlyvisible = false;

	/*CSprite@ sprite = this.getSprite();
	sprite.getConsts().accurateLighting = false;
	sprite.SetEmitSound("Shell_Whistle.ogg");
	sprite.SetEmitSoundPaused(false);
	sprite.SetEmitSoundVolume(0.0f);
	sprite.SetEmitSoundSpeed(0.9f);*/
}

void onTick(CBlob@ this)
{
	Vec2f velocity = this.getVelocity();
	const f32 angle = velocity.Angle();
	this.setAngleDegrees(-angle);

	ParticleAnimated("SmallSmoke"+(1+XORRandom(2)), this.getPosition(), Vec2f(0, 0), 0.0f, 1.0f, 2, 0.0f, true);

	const f32 modifier = Maths::Max(0, velocity.y * 0.02f);
	this.getSprite().SetEmitSoundVolume(Maths::Max(0, modifier));

	if (isServer())
	{
		Vec2f hitpos;
		CMap@ map = getMap();
		if (map.rayCastSolidNoBlobs(this.getOldPosition(), this.getPosition(), hitpos))
		{
			setPositionToLastOpenArea(this, hitpos, map);
			this.server_Die();
		}
	}
}

void setPositionToLastOpenArea(CBlob@ this, Vec2f hitpos, CMap@ map)
{
	//ensure we are exploding in an open area for maximum effect
	Vec2f original = hitpos;
	Vec2f dir = this.getOldVelocity();
	dir.Normalize();
	dir *= map.tilesize;

	for (u8 i = 0; i < 4; i++)
	{
		hitpos -= dir;
		if (!map.isTileSolid(hitpos)) break;
	}

	this.setPosition(hitpos);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!isServer()) return;

	if (blob is null) return;

	if (blob.isPlatform() && !solid) return;

	if (doesCollideWithBlob(this, blob))
	{
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	const bool willExplode = this.getTeamNum() == blob.getTeamNum() ? blob.getShape().isStatic() : true; 
	if (blob.isCollidable() && willExplode)
	{
		CPlayer@ player = blob.getPlayer();
		if (player !is null && player is this.getDamageOwnerPlayer()) return false;

		return true;
	}
	return false;
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

void DoExplosion(CBlob@ this)
{
	Vec2f velocity = this.getOldVelocity();

	Random rand(this.getNetworkID());
	Explode(this, 80.0f, 5.0f);
	for (u8 i = 0; i < 4; i++)
	{
		Vec2f jitter = Vec2f((int(rand.NextRanged(200)) - 100) / 200.0f, (int(rand.NextRanged(200)) - 100) / 200.0f);
		LinearExplosion(this, Vec2f(velocity.x * jitter.x, velocity.y * jitter.y), 32.0f + rand.NextRanged(32), 24.0f, 4, 10.0f, Hitters::explosion);
	}

	this.getSprite().Gib();
}
