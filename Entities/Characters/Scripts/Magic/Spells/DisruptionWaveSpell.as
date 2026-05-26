// Disruption Wave Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class DisruptionWaveSpell : Spell
{
	DisruptionWaveSpell()
	{
		name = "Disruption Wave";
		result_name = "disruptionwave";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 25;
		cooldown_time = 0;
		auto_cast = false;
		fragile = false;
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		CSprite@ sprite = caster.getSprite();
		sprite.PlaySound("DisruptionWaveStart.ogg", 3.0f, 1.2f);
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		caster.getShape().SetGravityScale(0.5f);
		caster.setVelocity(Vec2f_zero);

		vars.spell_position = getPos(caster);

		if (isClient())
		{
			if (getGameTime() % 8 == 0)
			{
				Vec2f particle_pos = vars.spell_position + Vec2f(XORRandom(5)-2, XORRandom(5)-2);
				ParticleDisruptionSpark(particle_pos);
			}

			ParticleEnergyVortex(vars.spell_position, 20.0f);
		}
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		RemoveEffects(caster);

		if (isServer())
		{
			Vec2f pos = getPos(caster);
			Vec2f direction = getDirection(caster);

			CBlob@ result = server_CreateBlobNoInit(result_name);
			if (result !is null)
			{
				result.setPosition(pos);
				result.server_setTeamNum(caster.getTeamNum());
				result.SetDamageOwnerPlayer(caster.getPlayer());
				result.set_Vec2f("boom_direction", direction);
				result.Init();
			}
		}
	}

	void onInterrupted(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onInterrupted(caster, vars);

		RemoveEffects(caster);
	}

	void RemoveEffects(CBlob@ caster)
	{
		caster.getShape().SetGravityScale(1.0f);
	}
	
	Vec2f getDirection(CBlob@ caster)
	{
		Vec2f norm = caster.getAimPos() - caster.getPosition();
		norm.Normalize();
		return norm;
	}

	Vec2f getPos(CBlob@ caster)
	{
		return caster.getPosition() + getDirection(caster) * 16.0f;
	}

	void ParticleDisruptionSpark(Vec2f pos)
	{
		CParticle@ p = ParticleAnimated("DisruptionSpark.png", pos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true);
		if (p !is null)
		{
			p.Z = 500.0f;
			p.collides = false;
			p.gravity = Vec2f_zero;
		}
	}
}
