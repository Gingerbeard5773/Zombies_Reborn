// Energy Beam Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class EnergyBeamSpell : Spell
{
	MagicCircle@ circle;

	EnergyBeamSpell()
	{
		name = "Energy Beam";
		result_name = "energybeam";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 30 * 4;
		cooldown_time = 600;
		auto_cast = true;
		fragile = false;

		@circle = MagicCircle(0.05f, 1.0f, true);

		MagicCircleLayer@ layer = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.15f, 10.0f);
		circle.AddLayer(layer);
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		circle.Setup(caster);

		CSprite@ sprite = caster.getSprite();
		sprite.SetEmitSound("SpellLoop.ogg");
		sprite.SetEmitSoundSpeed(1.4f);
		sprite.SetEmitSoundVolume(0.1f);
		sprite.SetEmitSoundPaused(false);
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		vars.spell_position = getPos(caster);

		if (isClient())
		{
			ParticleEnergyVortex(vars.spell_position, 20.0f);

			ParticleMagic(vars.spell_position, "MissileFire3.png");

			if (vars.cast_time < 9 || vars.cast_time > time_to_cast - 9)
			{
				circle.current_scale = Maths::Min(circle.current_scale + circle.scale_speed, circle.target_scale);
			}

			CSprite@ sprite = caster.getSprite();
			const f32 volume = Maths::Min(sprite.getEmitSoundVolume() + 0.03f, 1.0f);
			sprite.SetEmitSoundVolume(volume);

			//const f32 speed = sprite.getEmitSoundSpeed() + 0.01f;
			//sprite.SetEmitSoundSpeed(speed);

			circle.position = vars.spell_position;
			circle.Tick(caster);
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
				result.set_netid("owner_netid", caster.getNetworkID());
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
		circle.Remove(caster);

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

	void setBotAimPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		// Aim pos is lerped so this spell can be dodged by players easier
		Vec2f aim_pos = Vec2f_lerp(caster.getAimPos(), pos, 0.15f);
		caster.setAimPos(aim_pos);
	}
}
