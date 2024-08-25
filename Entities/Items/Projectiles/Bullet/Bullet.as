
#include "Hitters.as";
#include "MakeDustParticle.as";
#include "ParticleSparks.as";

const f32 PUSH_FORCE = 22.0f;

void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
    consts.mapCollisions = false;
	consts.bullet = true;
	consts.net_threshold_multiplier = 4.0f;
	this.server_SetTimeToDie(this.get_f32("bullet time"));	
	this.Tag("projectile");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
    if (blob !is null)
    {
		if (blob.isPlatform() && CollidesWithPlatform(this, blob, normal)) return;

		if ((blob.isCollidable() && blob.getShape().isStatic()) || (blob.hasTag("flesh") && this.getTeamNum() != blob.getTeamNum())) 
		{
			const u8 pierced = this.get_u8("pierced");

			this.server_Hit(blob, point1, normal, this.get_f32("bullet damage") * (pierced > 1 ? 0.5f : 1.0f), Hitters::arrow);
			if (pierced > 1)
				this.server_Die();

			this.set_u8("pierced", pierced + 1);
		}
	}
}

bool CollidesWithPlatform(CBlob@ this, CBlob@ blob, Vec2f velocity)
{
	f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}

void onTick(CBlob@ this)
{
    const f32 angle = this.getVelocity().Angle();
    this.setAngleDegrees(-angle);
	
	Vec2f end;
	if (getMap().rayCastSolidNoBlobs(this.getShape().getVars().oldpos, this.getPosition(), end))
	{
		HitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
	}
}

f32 HitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
    if (hitBlob !is null)
    {
		this.getSprite().PlaySound("BulletImpact.ogg");	
    }

	return damage;
}

void HitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	this.getSprite().PlaySound(XORRandom(4) == 0 ? "BulletRicochet.ogg" : "BulletImpact.ogg");
	MakeDustParticle(worldPoint, "/DustSmall.png");
	CMap@ map = getMap();
	f32 vellen = velocity.Length();
	TileType tile = map.getTile(worldPoint).type;
	if (map.isTileCastle(tile) || map.isTileStone(tile))
	{
		sparks(worldPoint, -velocity.Angle(), Maths::Max(vellen*0.05f, damage));
	}
	this.server_Die();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (this !is hitBlob)
	{
		// affect players velocity
		const f32 force = (PUSH_FORCE * -0.125f) * Maths::Sqrt(hitBlob.getMass()+1);
		hitBlob.AddForce(velocity * force);
	}
}
