// Firebolt Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"
#include "ParticleLightning.as"

class ChainLightningSpell : Spell
{
	ChainLightningSpell()
	{
		name = "Chain Lightning";
		result_name = "chainlightning";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 90;
		cooldown_time = 300;
		auto_cast = true;
		fragile = false;
	}
	
	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		CBlob@ spellemit = getEmit(caster);
		if (spellemit !is null)
		{
			CSprite@ emitsprite = spellemit.getSprite();
			emitsprite.SetEmitSound("LightningLoop0.ogg");
			emitsprite.SetEmitSoundVolume(1.0f);
			emitsprite.SetEmitSoundSpeed(1.0f);
			emitsprite.SetEmitSoundPaused(false);
			spellemit.setPosition(vars.spell_position);
		}
	}
	
	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		if (!isClient()) return;

		vars.spell_position = getPos(caster);

		if (XORRandom(30) == 0)
		{
			Sound::Play("lightning"+(1), vars.spell_position);
		}
		
		if (XORRandom(5) == 0)
		{
			Vec2f random_offset = Vec2f(XORRandom(40) - 20, XORRandom(40) - 20);
			DrawLightningSegment(vars.spell_position, vars.spell_position + random_offset, 3, 10.0f, lightning_random);
		}

		const f32 progress = (f32(vars.cast_time) / f32(time_to_cast));
		const int interval = Maths::Max(1, int(time_to_cast * (1.0f - progress)));

		if (vars.cast_time % interval == 0)
		{
			Sound::Play("LightningLoop1", vars.spell_position);
		}

		CBlob@ spellemit = getEmit(caster);
		if (spellemit !is null)
		{
			spellemit.setPosition(vars.spell_position);
		}

		CParticle@ p = ParticleAnimated("DisruptionSpark.png", vars.spell_position, Vec2f_zero, XORRandom(361), 0.8f, 1, 0.0f, true);
		if (p !is null)
		{
			p.Z = 500.0f;
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.scale = progress;
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

			CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), pos);
			if (result !is null)
			{
				result.SetDamageOwnerPlayer(caster.getPlayer());
				result.setAngleDegrees(-direction.Angle());
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
		CBlob@ spellemit = getEmit(caster);
		if (spellemit !is null)
		{
			spellemit.getSprite().SetEmitSoundPaused(true);
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
		return caster.getPosition() + getDirection(caster) * 14.0f;
	}


	/// BOTS

	void setBotAimPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		// Aim pos is lerped so this spell can be dodged by players easier
		Vec2f aim_pos = Vec2f_lerp(caster.getAimPos(), pos, 0.15f);
		caster.setAimPos(aim_pos);
	}
}
