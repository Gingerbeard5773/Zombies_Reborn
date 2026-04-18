// Gold effects

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f && isClient()) //sound for all damage
	{
		if (hitterBlob !is this)
		{
			this.getSprite().PlaySound("dig_stone", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
		}

		Vec2f vel = getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f);
		makeGibParticle("GoldRocks", worldPoint, vel, 1, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	return damage;
}

void onGib(CSprite@ this)
{
	if (this.getBlob().hasTag("heavy weight"))
	{
		this.PlaySound("WoodDestruct");
	}
	else
	{
		this.PlaySound("LogDestruct");
	}
}
