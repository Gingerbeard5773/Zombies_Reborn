// Incineration Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class IncinerateSpell : Spell
{
	MagicCircle@ circle;
	SColor color(255, 230, 110, 20);

	IncinerateSpell()
	{
		name = "Incinerate";
		result_name = "firebomb";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 45;
		cooldown_time = 450;
		auto_cast = true;
		fragile = false;

		@circle = MagicCircle(0.05f, 0.5f, true);

		MagicCircleLayer@ layer1 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.4f, 2.0f, color);
		MagicCircleLayer@ layer2 = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.35f, -2.0f, color);
		
		SColor red(255, 226, 10, 0);
		MagicCircleLayer@ layer3 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.5f, 2.0f, red);

		circle.AddLayer(layer1);
		circle.AddLayer(layer2);
		circle.AddLayer(layer3);
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		if (isClient())
		{
			circle.position = vars.spell_position;
			circle.Setup(caster);

			Sound::Play("SpriteFire1.ogg", vars.spell_position, 1.5f, 0.85f);

			CSprite@ sprite = caster.getSprite();
			sprite.SetEmitSound("SpellLoop.ogg");
			sprite.SetEmitSoundSpeed(0.85f);
			sprite.SetEmitSoundPaused(false);
		}
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		if (!isClient()) return;

		if (vars.cast_time < 20)
		{
			circle.current_scale = Maths::Min(circle.current_scale + circle.scale_speed, circle.target_scale);
		}
		else if (vars.cast_time > time_to_cast - 10)
		{
			circle.current_scale = Maths::Max(circle.current_scale - circle.scale_speed, 0.1f);
		}
		
		MagicCircleLayer@ layer = circle.layers[2];
		layer.scale = Maths::Max(layer.scale - 0.013f, 0.05f);

		if (getGameTime() % 5 == 0)
		{
			const f32 pitch = 0.8f + XORRandom(10) / 100.0f;
			Sound::Play("SpriteFire1.ogg", vars.spell_position, 1.0f, pitch);
			ParticleCasterLine(caster.getPosition(), vars.spell_position, color);
		}

		ParticleEnergyVortex(vars.spell_position);

		circle.Tick(caster);
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), vars.spell_position); 
			if (result !is null)
			{
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
			RemoveEffects(caster);
		}
	}

	void onInterrupted(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onInterrupted(caster, vars);

		if (isClient())
		{
			ParticleMagicCircleVanish(vars.spell_position, 30.0f * circle.current_scale, color);

			RemoveEffects(caster);
		}
	}
	
	void RemoveEffects(CBlob@ caster)
	{
		caster.getSprite().SetEmitSoundPaused(true);

		circle.layers[2].scale = 0.5f;

		circle.Remove(caster);
	}
}
