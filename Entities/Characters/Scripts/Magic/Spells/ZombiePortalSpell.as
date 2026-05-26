// Zombie Portal Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class ZombiePortalSpell : Spell
{
	MagicCircle@ circle;
	SColor color(255, 113, 34, 145);

	ZombiePortalSpell()
	{
		name = "Zombie Portal";
		result_name = "zombieportal";
		icon_name = "$orb$";
		tier = SpellTier::TierIII;
		time_to_cast = 30 * 8;
		cooldown_time = 3000;
		auto_cast = true;
		fragile = true;

		@circle = MagicCircle(0.05f, 1.0f, true);

		MagicCircleLayer@ layer1 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.4f, 2.0f, color);
		MagicCircleLayer@ layer2 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.17f, 2.0f, color);
		MagicCircleLayer@ layer3 = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.35f, -2.0f, color);
		MagicCircleLayer@ layer4 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.5f, -2.0f, color);

		circle.AddLayer(layer1);
		circle.AddLayer(layer2);
		circle.AddLayer(layer3);
		circle.AddLayer(layer4);
	}

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onStart(caster, vars);

		if (isClient())
		{
			circle.position = vars.spell_position;
			circle.Setup(caster);

			Sound::Play("BlackHoleMake.ogg", vars.spell_position, 2.0f);

			CSprite@ sprite = caster.getSprite();
			sprite.SetEmitSound("SpellLoop.ogg");
			sprite.SetEmitSoundSpeed(0.85f);
			sprite.SetEmitSoundPaused(false);

			CBlob@ spellemit = getEmit(caster);
			if (spellemit !is null)
			{
				CSprite@ emitsprite = spellemit.getSprite();
				emitsprite.SetEmitSound("SpellLoop1.ogg");
				emitsprite.SetEmitSoundVolume(6.0f);
				emitsprite.SetEmitSoundSpeed(0.75f);
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
		
		if (vars.cast_time == time_to_cast - 20)
		{
			Sound::Play("PortalOpen.ogg", vars.spell_position, 2.0f);
		}

		if (getGameTime() % 5 == 0)
		{
			ParticleCasterLine(caster.getPosition(), vars.spell_position, color);
		}

		circle.Tick(caster);
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		SetTierIIICooldown(caster, vars);

		if (isServer())
		{
			CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), vars.spell_position);
			if (result !is null)
			{
				result.SetDamageOwnerPlayer(caster.getPlayer());
			}
		}

		if (isClient())
		{
			Sound::Play("BuildingExplosion.ogg", vars.spell_position, 2.0f, 0.9f);
			Sound::Play("Bomb.ogg", vars.spell_position, 2.0f, 0.9f);

			Vec2f offset(16, 16);
			for (u8 i = 0; i < 8; ++i)
			{
				CParticle@ p = ParticleAnimated("FireFlash.png", vars.spell_position + offset, offset/16, -offset.Angle(), 1.0f, 2, 0.0f, true);
				if (p !is null)
				{
					p.Z = 1000.0f;
				}
				offset.RotateBy(45);
			}

			RemoveEffects(caster);
		}
	}

	void onInterrupted(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onInterrupted(caster, vars);

		SetTierIIICooldown(caster, vars);

		if (isClient())
		{
			ParticleMagicCircleVanish(vars.spell_position, 30.0f * circle.current_scale, color);
			Sound::Play("BlackHoleDie.ogg", vars.spell_position, 2.0f);

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

	void SetTierIIICooldown(CBlob@ caster, WizardVars@ vars)
	{
		for (int i = 0; i < vars.spells.length; i++)
		{
			Spell@ spell = vars.spells[i];
			if (spell.tier != SpellTier::TierIII) continue;

			spell.next_cast_time = getGameTime() + cooldown_time;
		}
	}


	/// BOTS

	Vec2f bot_start_pos;

	void setBotStartPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		Navigator navigator(pos);
		navigator.cost_evaluators = { @getRandomCost, CostHandle(@getOriginDistanceCost) };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isOnGround, ValidHandle(@isSupportedByDirt) };

		Vec2f[] candidates;
		CMap@ map = getMap();
		const f32 map_height = map.tilemapheight * 8;
		f32 current_y = Maths::Max(30 * 8, pos.y);
		while (current_y < map_height && candidates.length == 0)
		{
			Vec2f check_pos(pos.x, current_y);
			candidates = navigator.getValidPositionsInBox(check_pos, 30, 30);

			current_y += 30 * 8;
		}

		if (candidates.length == 0)
		{
			navigator.cost_evaluators = { @getRandomCost, CostHandle(@getOriginDistanceCost) };
			navigator.valid_evaluators = { @isInMap, ValidHandle(@isSupportedByDirt) };
			Vec2f tl(pos.x - 8, 0);
			Vec2f br(pos.x + 8, map.tilemapwidth * 8);
			candidates = navigator.getValidPositionsInBox(tl, br);
		}

		bot_start_pos = navigator.getBestPosition(candidates) + Vec2f(0, -16);
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
		navigator.proximity = 120.0f;
		navigator.cost_evaluators = { @getProximityCost, @getRandomCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace };
		return navigator.getBestPositionFromOrigin(40, 40);
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

	f32 getOriginDistanceCost(Vec2f pos, Navigator@ navigator)
	{
		const f32 cost = (pos - navigator.origin).Length() * 0.1f;
		return cost;
	}

	bool isSupportedByDirt(Vec2f pos, Navigator@ navigator)
	{
		CMap@ map = getMap();
		for (int i = -1; i < 3; i++)
		{
			Vec2f check_pos = pos + Vec2f(0, i * 8);
			if (map.getTile(check_pos).dirt == 80) return true;
		}
		return false;
	}
}
