// Nuke Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"
#include "SpatialNavigator.as"
#include "CustomTiles.as"

class EnergyBeamStormSpell : Spell
{
	MagicCircle@ circle;
	SColor color(255, 255, 255, 255);

	EnergyBeamStormSpell()
	{
		name = "Energy Beam Storm";
		result_name = "energybeamstorm";
		icon_name = "$orb$";
		tier = SpellTier::TierIII;
		time_to_cast = 30 * 8;
		cooldown_time = 3000;
		auto_cast = true;
		fragile = true;

		@circle = MagicCircle(0.05f, 1.0f, true);

		MagicCircleLayer@ layer1 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.2f, -2.0f, color);
		MagicCircleLayer@ layer2 = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.4f, 2.0f, color);
		MagicCircleLayer@ layer3 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.5f, -2.0f, color);
		MagicCircleLayer@ layer4 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.65f, 2.0f, color);
		MagicCircleLayer@ layer5 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.8f, -2.0f, color);

		circle.AddLayer(layer1);
		circle.AddLayer(layer2);
		circle.AddLayer(layer3);
		circle.AddLayer(layer4);
		circle.AddLayer(layer5);
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
				emitsprite.SetEmitSound("PortalLoop.ogg");
				emitsprite.SetEmitSoundVolume(6.0f);
				emitsprite.SetEmitSoundSpeed(1.0f);
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

		if (vars.cast_time == time_to_cast - 10)
		{
			CParticle@ p = ParticleAnimated("Flash2.png", vars.spell_position, Vec2f(0,0), 90.0f, 1.5f, 2, 0.0f, true);
			if (p !is null)
			{
				p.Z = 700.0f;
			}
		}
		
		if (vars.cast_time == time_to_cast - 20)
		{
			Sound::Play("LaserOrbWindup.ogg", vars.spell_position, 5.0f, 1.0f);
		}

		const f32 progress = 1.0f - (f32(vars.cast_time) / f32(time_to_cast));
		const int interval = Maths::Max(1, int(time_to_cast * progress));

		if (vars.cast_time % interval == 0)
		{
			Vec2f spawn_position = Vec2f(vars.spell_position.x, -300.0f);
			Vec2f map_bottom = Vec2f(vars.spell_position.x, getMap().getMapDimensions().y);
			ParticleCasterLine(spawn_position, map_bottom, color);
			Sound::Play("individual_boom.ogg", vars.spell_position, 5.0f, 1.0f);
		}

		if (getGameTime() % 5 == 0)
		{
			ParticleCasterLine(caster.getPosition(), vars.spell_position, color);
		}

		ParticleEnergyVortex(vars.spell_position, 80.0f);

		circle.Tick(caster);
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		SetTierIIICooldown(caster, vars);

		RemoveEffects(caster);

		if (isServer())
		{
			Vec2f spawn_position = Vec2f(vars.spell_position.x, -300.0f);
			CBlob@ result = server_CreateBlobNoInit(result_name);
			if (result !is null)
			{
				result.server_setTeamNum(caster.getTeamNum());
				result.setPosition(spawn_position);
				result.set_netid("owner_netid", caster.getNetworkID());
				result.SetDamageOwnerPlayer(caster.getPlayer());
				result.Init();
				result.setAngleDegrees(-90.0f);
			}
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

	void SetTierIIICooldown(CBlob@ caster, WizardVars@ vars)
	{
		for (int i = 0; i < vars.spells.length; i++)
		{
			Spell@ spell = vars.spells[i];
			if (spell.tier != SpellTier::TierIII) continue;

			spell.next_cast_time = getGameTime() + cooldown_time;
		}
	}

	void RemoveEffects(CBlob@ caster)
	{
		if (!isClient()) return;

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

	void setBotStartPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		Navigator navigator(pos);
		navigator.cost_evaluators = { CostHandle(@getOriginDistanceCost), CostHandle(@getFortressCost) };
		Vec2f[]@ candidates = getValidPositions(navigator);
		bot_start_pos = navigator.getBestPosition(candidates);
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
		navigator.proximity = 200.0f;
		navigator.cost_evaluators = { @getProximityCost, @getRandomCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace };
		return navigator.getBestPositionFromOrigin(60, 60);
	}

	void onBotInterrupted(CBlob@ caster, WizardVars@ vars) 
	{
		Spell::onBotInterrupted(caster, vars);

		if (isClient())
		{
			Sound::Play("SpellFail.ogg", vars.spell_position, 2.0f);
			Sound::Play("SpellFail.ogg", caster.getPosition(), 1.0f);
		}
	}

	Vec2f[]@ getValidPositions(Navigator@ navigator)
	{
		CMap@ map = getMap();
		const int node_size = 10;
		const int nodes_x = (map.tilemapwidth / node_size) - 1;
		const int nodes_y = (map.tilemapheight / node_size) - 1;

		Vec2f start_pos = Vec2f(node_size, node_size) * 8;

		Vec2f[] candidates;

		for (int x = 0; x < nodes_x; x++)
		{
			for (int y = 0; y < nodes_y; y++)
			{
				Vec2f candidate = start_pos + Vec2f(x, y) * 8 * node_size;
				if (!navigator.isValid(candidate)) continue;

				candidates.push_back(candidate);
			}
		}

		return candidates;
	}

	f32 getFortressCost(Vec2f pos, Navigator@ navigator)
	{
		f32 cost = 0.0f;

		// Assess tiles in the area, player placed tiles remove cost
		CMap@ map = getMap();
		const int node_size = 10;
		const int attempts = (node_size * node_size) * 0.25f;
		for (int i = 0; i < attempts; i++)
		{
			const f32 rand_x = (XORRandom(node_size * 2 + 1) - node_size) * 8.0f;
			const f32 rand_y = (XORRandom(node_size * 2 + 1) - node_size) * 8.0f;
			Vec2f check_pos = pos + Vec2f(rand_x, rand_y);
			Tile tile = map.getTile(check_pos);

			if (map.isTileCastle(tile.type))     cost -= 1.0f;
			else if (isTileIron(tile.type))      cost -= 2.0f;
			else if (isTileGoldBlock(tile.type)) cost -= 3.0f;
		}

		// Assess blobs in the area, player placed buildings remove cost
		CBlob@[] blobs;
		if (map.getBlobsInRadius(pos, node_size * 8, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.hasTag("building")) cost -= 3.0f;
			}
		}
		
		return cost;
	}

	f32 getOriginDistanceCost(Vec2f pos, Navigator@ navigator)
	{
		const f32 cost = (pos - navigator.origin).Length() * 0.025f;
		return cost;
	}
}
