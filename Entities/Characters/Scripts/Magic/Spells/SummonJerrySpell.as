// Summon Jerry Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"
#include "FireParticle.as"

class SummonJerrySpell : Spell
{
	MagicCircle@ circle;
	SColor color(255, 148, 27, 27);

	SummonJerrySpell()
	{
		name = "Summon Jerry";
		result_name = "jerry";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 30 * 4;
		cooldown_time = 1500;
		auto_cast = true;
		fragile = true;

		@circle = MagicCircle(0.05f, 1.0f, true);

		MagicCircleLayer@ layer1 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.3f, 2.0f, color);
		MagicCircleLayer@ layer2 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.07f, 2.0f, color);
		MagicCircleLayer@ layer3 = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.25f, -2.0f, color);

		circle.AddLayer(layer1);
		circle.AddLayer(layer2);
		circle.AddLayer(layer3);
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		if (isClient())
		{
			Sound::Play("BlackHoleMake.ogg", vars.spell_position, 1.0f);

			circle.position = vars.spell_position;
			circle.Setup(caster);

			CSprite@ sprite = caster.getSprite();
			sprite.SetEmitSound("SpellLoop.ogg");
			sprite.SetEmitSoundVolume(0.75f);
			sprite.SetEmitSoundSpeed(0.85f);
			sprite.SetEmitSoundPaused(false);

			CBlob@ spellemit = getEmit(caster);
			if (spellemit !is null)
			{
				CSprite@ emitsprite = spellemit.getSprite();
				emitsprite.SetEmitSound("SpellLoop1.ogg");
				emitsprite.SetEmitSoundVolume(6.0f);
				emitsprite.SetEmitSoundSpeed(0.5f);
				emitsprite.SetEmitSoundPaused(false);
				spellemit.setPosition(vars.spell_position);
			}
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
		else if (vars.cast_time > time_to_cast - 20)
		{
			circle.current_scale = Maths::Max(circle.current_scale - circle.scale_speed, 0.1f);
		}

		Vec2f random_pos = Vec2f(XORRandom(40) - 20, XORRandom(40) - 20) * circle.current_scale;
		makeFireParticle(vars.spell_position + random_pos);

		if (getGameTime() % 5 == 0)
		{
			ParticleCasterLine(caster.getPosition(), vars.spell_position, color);
		}

		/*CBlob@ spellemit = getEmit(caster);
		if (spellemit !is null)
		{
			CSprite@ emitsprite = spellemit.getSprite();
			const f32 speed = emitsprite.getEmitSoundSpeed();
			emitsprite.SetEmitSoundSpeed(speed + 0.001f);
		}*/

		circle.Tick(caster);
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			CBlob@ result = server_CreateBlob("jerry", caster.getTeamNum(), vars.spell_position);
		}

		if (isClient())
		{
			Sound::Play("Summon1.ogg", vars.spell_position, 2.0f);
			
			ParticleZombieLightning(vars.spell_position);

			RemoveEffects(caster);
		}
	}

	void onInterrupted(CBlob@ caster, WizardVars@ vars)
	{
		next_cast_time = getGameTime() + cooldown_time;

		Spell::onInterrupted(caster, vars);

		if (isClient())
		{
			ParticleMagicCircleVanish(vars.spell_position, 30.0f * circle.current_scale, color);
			Sound::Play("BlackHoleDie.ogg", vars.spell_position, 1.0f, 0.85f);

			RemoveEffects(caster);
		}
	}

	void RemoveEffects(CBlob@ caster)
	{
		caster.getSprite().SetEmitSoundPaused(true);

		CBlob@ spellemit = getEmit(caster);
		if (spellemit !is null)
		{
			spellemit.getSprite().SetEmitSoundPaused(true);
		}

		circle.Remove(caster);
	}


	/// BOTS

	Vec2f bot_start_pos;

	void setBotAimPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		// Aim pos is lerped so this spell can be dodged by players easier
		Vec2f aim_pos = Vec2f_lerp(caster.getAimPos(), pos, 0.15f);
		caster.setAimPos(aim_pos);
	}

	void setBotStartPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		Navigator navigator(pos);
		navigator.cost_evaluators = { @getRandomCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace };
		bot_start_pos = navigator.getBestPositionFromOrigin(30, 30);
	}

	Vec2f getBotStartPos(CBlob@ caster, WizardVars@ vars)
	{
		if (bot_start_pos == Vec2f_zero)
		{
			setBotStartPos(caster, vars, caster.getPosition());
		}

		return bot_start_pos;
	}

	Vec2f getBotMovePos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		Navigator navigator(bot_start_pos);
		navigator.cost_evaluators = { @getProximityCost, @getRandomCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace };
		return navigator.getBestPositionFromOrigin(30, 30);
	}

	void onBotInterrupted(CBlob@ caster, WizardVars@ vars) 
	{
		Spell::onBotInterrupted(caster, vars);

		if (isClient())
		{
			Sound::Play("SpellFail.ogg", vars.spell_position, 3.0f);
			Sound::Play("SpellFail.ogg", caster.getPosition(), 2.0f);
		}
	}

	bool canBotCast(CBlob@ caster, WizardVars@ vars)
	{
		return caster.getTickSinceCreated() > 1800;
	}
}
