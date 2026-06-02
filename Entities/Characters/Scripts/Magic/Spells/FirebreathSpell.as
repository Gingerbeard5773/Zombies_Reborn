// Firebreath Spell Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class FirebreathSpell : Spell
{
	FirebreathSpell()
	{
		name = "Fire Wave";
		result_name = "firebreath";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 80;
		cooldown_time = 240;
		auto_cast = false;
		fragile = false;
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		CSprite@ sprite = caster.getSprite();
		sprite.SetEmitSound("FireBlastLoop.ogg");
		sprite.SetEmitSoundSpeed(0.5f);
		sprite.SetEmitSoundVolume(0.1f);
		sprite.SetEmitSoundPaused(false);
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		vars.spell_position = getPos(caster);

		if (isClient())
		{
			CSprite@ sprite = caster.getSprite();
			const f32 volume = Maths::Min(sprite.getEmitSoundVolume() + 0.01f, 0.8f);
			sprite.SetEmitSoundVolume(volume);

			const f32 speed = Maths::Min(sprite.getEmitSoundSpeed() + 0.01f, 0.8f);
			sprite.SetEmitSoundSpeed(speed);

			const int amount = Maths::Min(vars.cast_time * 0.05f, 10);
			for (int i = 0; i < amount; i++)
			{
				CParticle@ p = ParticleMagic(vars.spell_position, "RocketFire3.png");
				if (p is null) continue;

				p.velocity *= 2.5f;
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
		CSprite@ sprite = caster.getSprite();
		sprite.SetEmitSoundPaused(true);
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


	/// BOTS

	Vec2f getBotMovePos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		Navigator navigator(pos);
		navigator.proximity = 32.0f;
		navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getVisibleCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isUnobstructedByBlobs };
		return navigator.getBestPositionFromOrigin(15, 15);
	}
}
