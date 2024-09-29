//Gingerbeard @ September 29, 2024

#include "Hitters.as";
#include "FireParticle.as"
#include "ArcherCommon.as";
#include "BombCommon.as";
#include "KnockedCommon.as"

const f32 ARROW_PUSH_FORCE = 6.0f;

//Molotov arrow logic

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(20.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));

	CSprite@ sprite = this.getSprite();
	{
		Animation@ anim = sprite.addAnimation("molotov arrow", 0, false);
		anim.AddFrame(16);
		sprite.SetAnimation(anim);
	}
	sprite.SetEmitSound("MolotovBurning.ogg");
	sprite.SetEmitSoundVolume(5.0f);
	sprite.SetEmitSoundPaused(false);
}

void onTick(CBlob@ this)
{
	if (this.hasTag("collided")) return;

	ParticleAnimated("SmallFire", this.getPosition(), Vec2f(0, -1 - XORRandom(2)), 0, 1.0f, 2, 0.25f, false);

	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if (pos.x < 0.1f ||
		pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	const f32 angle = this.getVelocity().Angle();
	Pierce(this);
	this.setAngleDegrees(-angle);

	CShape@ shape = this.getShape();
	if (shape.vellen > 0.0001f)
	{
		if (shape.vellen > 13.5f)
		{
			shape.SetGravityScale(0.1f);
		}
		else
		{
			shape.SetGravityScale(Maths::Min(1.0f, 1.0f / (shape.vellen * 0.1f)));
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob !is null && doesCollideWithBlob(this, blob) && !this.hasTag("collided"))
	{
		/*CShape@ shape = blob.getShape();
		if (shape !is null && !shape.isStatic())
		{
			Vec2f velnorm = this.getVelocity();
			f32 vellen = Maths::Min(this.getRadius(), velnorm.Normalize() * (1.0f / 30.0f));
			Vec2f betweenpos = (this.getPosition() + this.getOldPosition()) * 0.5;
			this.setPosition(betweenpos - (velnorm * vellen));
		}*/

		this.Tag("collided");
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile")) return false;

	if (blob.hasTag("ignore_arrow")) return false;

	const bool willExplode = this.getTeamNum() != blob.getTeamNum() || blob.getShape().isStatic(); 
	return blob.isCollidable() && willExplode;
}

void Pierce(CBlob@ this, CBlob@ blob = null)
{
	Vec2f end;
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();
	if (getMap().rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
	{
		this.Tag("collided");
		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSoundPaused(true);
		//sprite.PlaySound("GlassBreak");
		sprite.PlaySound("MolotovExplosion.ogg", 1.6f);
		sprite.Gib();
	}
	
	if (isServer())
	{
		CMap@ map = getMap();
		Vec2f pos = this.getPosition();
		const int radius = 2; //size of the circle
		const f32 radsq = radius * 8 * radius * 8;
		for (int x_step = -radius; x_step < radius; ++x_step)
		{
			for (int y_step = -radius; y_step < radius; ++y_step)
			{
				Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
				if (off.LengthSquared() > radsq) continue;
				
				map.server_setFireWorldspace(pos + off, true);
			}
		}

		Vec2f vel = this.getOldVelocity();
		for (int i = 0; i < 6 + XORRandom(2); i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos + Vec2f(0, -8));
			if (blob is null) continue;

			Vec2f nv = Vec2f((XORRandom(100) * 0.01f * vel.x * 1.30f), -(XORRandom(100) * 0.01f * 3.00f));
			if (Maths::Abs(nv.x) < 1.0f)
			{
				nv.x = XORRandom(nv.Length() * 2 * 100)/100;
				if (XORRandom(100) < 50) nv.x *= -1;
			}

			blob.setVelocity(nv);
			blob.server_SetTimeToDie(5 + XORRandom(6));
			blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::sword)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (this is hitBlob) return;

	// affect players velocity

	Vec2f vel = velocity;
	const f32 speed = vel.Normalize();
	if (speed > ArcherParams::shoot_max_vel * 0.5f)
	{
		f32 force = (ARROW_PUSH_FORCE * 0.125f) * Maths::Sqrt(hitBlob.getMass() + 1);

		if (this.hasTag("bow arrow"))
		{
			force *= 1.3f;
		}

		hitBlob.AddForce(velocity * force);

		// stun if shot real close
		if (this.getTickSinceCreated() <= 4 &&
			speed > ArcherParams::shoot_max_vel * 0.845f &&
			hitBlob.hasTag("player") && !hitBlob.hasTag("undead"))
		{
			setKnocked(hitBlob, 20, true);
			Sound::Play("/Stun", hitBlob.getPosition(), 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
		}
	}
}
