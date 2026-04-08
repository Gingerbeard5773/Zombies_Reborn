#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage <= 0.1f) return damage;

	doBloodEffects(this, worldPoint, velocity, damage, hitterBlob, customData);

	return damage;
}

void doBloodEffects(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (!isClient()) return;

	if (hitterBlob is this && customData != Hitters::crush) return;

	// cheap isOnScreen
	Driver@ driver = getDriver();
	Vec2f local_pos = driver.getWorldPosFromScreenPos(driver.getScreenCenterPos());
	if ((local_pos - worldPoint).LengthSquared() > 680.0f * 680.0f) return;

	bool showblood = true;

	switch (customData)
	{
		case Hitters::drown:
		case Hitters::burn:
		case Hitters::fire:
			showblood = false;
			break;

		case Hitters::sword:
			Sound::Play("SwordKill", this.getPosition());
			break;

		case Hitters::stab:
			if (this.getHealth() > 0.0f && damage > 2.0f)
			{
				this.Tag("cutthroat");
			}
			break;

		case Hitters::bite:
			break;

		default:
			Sound::Play("FleshHit.ogg", this.getPosition());
			break;
	}

	if (!showblood) return;

	worldPoint.y -= this.getRadius() * 0.5f;

	const f32 capped_damage = Maths::Min(damage, 2.0f);
	if (capped_damage > 1.0f)
	{
		ParticleBloodSplat(worldPoint, true);
	}

	if (capped_damage > 0.25f)
	{
		for (f32 count = 0.0f; count < capped_damage; count += 1.0f)
		{
			ParticleBloodSplat(worldPoint + getRandomVelocity(0, 0.75f + capped_damage * 2.0f * XORRandom(2), 360.0f), false);
		}
	}

	if (capped_damage > 0.01f && !v_fastrender)
	{
		f32 angle = (velocity).Angle();

		for (f32 count = 0.0f ; count < capped_damage + 0.6f; count += 0.2f)
		{
			Vec2f vel = getRandomVelocity(angle, 1.0f + 0.3f * capped_damage * 0.1f * XORRandom(40), 60.0f);
			vel.y -= 1.5f * capped_damage;
			ParticleBlood(worldPoint, vel * -1.0f);
			ParticleBlood(worldPoint, vel * 1.7f);
		}
	}
}

Random blood_random(54321);
SColor blood_color(255, 126, 0, 0);
CParticle@ ParticleBlood(Vec2f pos, Vec2f vel)
{
	CParticle@ p = ParticlePixelUnlimited(pos, vel, blood_color, false);
	if (p !is null)
	{
		p.fastcollision = true;
		p.timeout = 60 + blood_random.NextRanged(30);
		p.damping = 0.95f;
		p.gravity = Vec2f(0, 0.25f);
		p.bounce = 0.01f;
		p.waterdamping = 0.6f;
	}
	return p;
}
