// Magic Missile Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class MagicMissileSpell : Spell
{
	MagicMissileSpell()
	{
		name = "Magic Missiles";
		result_name = "magic_missile";
		icon_name = "$magic_missile$";
		tier = SpellTier::TierI;
		time_to_cast = 30 * 2;
		cooldown_time = 0;
		auto_cast = false;
		fragile = false;
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		vars.spell_position = getPos(caster);

		if (!isClient()) return;

		for (int i = 0; i < 1; i++)
		{
			const f32 angle = magic_random.NextFloat() * 360.0f;
			const f32 r = 0.1f * Maths::Sqrt(magic_random.NextFloat());

			Vec2f offset(r, 0);
			offset.RotateBy(angle);

			Vec2f particle_pos = vars.spell_position + offset;

			Vec2f vel = offset;
			if (vel.LengthSquared() > 0)
			{
				vel.Normalize();
				vel *= 0.25f + magic_random.NextFloat() * 1.5f;
			}

			CParticle@ p = ParticlePixelUnlimited(particle_pos, vel, color_white, true);
			if (p is null) continue;

			p.collides = false;
			p.timeout = 5 + magic_random.NextRanged(10);
			p.damping = 0.92f;
			p.gravity = Vec2f(0, 0);
			p.Z = 650.0f;
		}
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			const f32 spread = 10;

			Vec2f pos = caster.getPosition() + Vec2f(0.0f, -2.0f);
			Vec2f aim = caster.getAimPos();

			Vec2f vel = (aim - pos);
			vel.Normalize();
			vel *= 2.0f;

			for (u8 i = 0; i < 5; i++)
			{
				CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), pos);
				if (result is null) continue;

				result.IgnoreCollisionWhileOverlapped(caster);
				Vec2f newVel = vel;
				newVel.RotateBy(-spread + (spread * 0.5f) * i, Vec2f());
				result.setVelocity(newVel);

				CPlayer@ player = caster.getPlayer();
				result.SetDamageOwnerPlayer(player);

				if (player is null || player.isBot())
				{
					result.set_netid("owner_netid", caster.getNetworkID());
				}
			}
		}

		if (isClient())
		{
			caster.getSprite().PlaySound("MagicMissile.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
		}
	}

	Vec2f getDirection(CBlob@ caster)
	{
		Vec2f norm = caster.getAimPos() - caster.getPosition();
		norm.Normalize();
		return norm;
	}

	Vec2f getPos(CBlob@ caster)
	{
		return caster.getPosition() + getDirection(caster) * 8.0f;
	}
}
