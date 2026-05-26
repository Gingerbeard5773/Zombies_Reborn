// Spell Common
// Gingerbeard @ April 23, 2026

#include "SpatialNavigator.as"

// Register spells
#include "OrbSpell.as"
#include "NukeSpell.as"
#include "IncinerateSpell.as"
#include "MagicMissileSpell.as"
#include "EnergyBeamSpell.as"
#include "FireballSpell.as"
#include "FireboltSpell.as"
#include "TeleportSpell.as"
#include "DisruptionWaveSpell.as"
#include "FirebreathSpell.as"
#include "ChainLightningSpell.as"
#include "EnergyBeamStormSpell.as"
#include "ZombiePortalSpell.as"
#include "SummonJerrySpell.as"

namespace SpellTier
{
	enum Tier
	{
		TierI = 0,
		TierII,
		TierIII
	}
}

class WizardVars
{
	u8 spell_index = 0;
	u32 cast_time = 0;

	Vec2f spell_position = Vec2f_zero;

	Spell@ old_spell;
	Spell@ spell;
	Spell@[]@ spells;

	WizardVars(Spell@[]@ class_spells)
	{
		@spells = @class_spells;

		SetSpell(0);
	}

	void SetSpell(const u8&in index)
	{
		spell_index = index;
		if (spell_index >= spells.length) { error("Failed to set spell, index out of bounds [WizardVars]"); return; }

		@old_spell = spell;
		@spell = spells[spell_index];
	}

	void Synchronize(CBlob@ caster)
	{
		if (isServer() && isClient()) return;

		const u8 cmd = caster.getCommandID(isServer() ? "client_sync_wizardvars" : "server_sync_wizardvars");
		CBitStream stream;
		Serialize(stream);
		caster.SendCommand(cmd, stream);
	}

	void Serialize(CBitStream@ stream)
	{
		stream.write_u8(spell_index);
		stream.write_u32(cast_time);
		stream.write_Vec2f(spell_position);

		for (int i = 0; i < spells.length; i++)
		{
			spells[i].Serialize(stream);
		}
	}

	bool Unserialize(CBitStream@ stream)
	{
		if (!stream.saferead_u8(spell_index))       { error("Failed to access index [WizardVars]");    return false; }
		if (!stream.saferead_u32(cast_time))        { error("Failed to access time [WizardVars]");     return false; }
		if (!stream.saferead_Vec2f(spell_position)) { error("Failed to access position [WizardVars]"); return false; }

		for (int i = 0; i < spells.length; i++)
		{
			if (!spells[i].Unserialize(stream)) return false;
		}

		SetSpell(spell_index);

		return true;
	}
}

class Spell
{
	//consts
	string name = "Standard Spell";  // Descriptive name for the spell
	string result_name = "orb";      // blob name the spell produces
	string icon_name = "";           // Icon for spell menu
	u8 tier = SpellTier::TierI;      // Spell Tier for determining strength
	u32 time_to_cast = 30;           // Length of time it takes to charge up the spell
	u32 cooldown_time = 0;           // How long do we have to wait before casting the spell again
	bool auto_cast = false;          // Spell is cast instantly upon reaching charged state
	bool fragile = false;            // Bots - interrupts the spell if the bot gets hurt enough

	//vars
	u32 next_cast_time = 0;
	bool active = false;

	Spell() { }

	void onStart(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		if (caster.getPlayer() is null || caster.isBot())
		{
			onBotStart(caster, vars);
		}
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		if (caster.getPlayer() is null || caster.isBot())
		{
			onBotTick(caster, vars);
		}
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		vars.cast_time = 0;
		next_cast_time = getGameTime() + cooldown_time;
		active = false;

		if (caster.getPlayer() is null || caster.isBot())
		{
			onBotComplete(caster, vars);
		}
	}

	void onInterrupted(CBlob@ caster, WizardVars@ vars) 
	{
		//override me
		vars.cast_time = 0;
		active = false;

		if (caster.getPlayer() is null || caster.isBot())
		{
			onBotInterrupted(caster, vars);
		}
	}

	bool canCast(CBlob@ caster, WizardVars@ vars)
	{
		if (caster.getPlayer() is null || caster.isBot())
		{
			if (!canBotCast(caster, vars)) return false;
		}

		return getTimeRemainingTillReady() == 0;
	}

	u32 getTimeRemainingTillReady()
	{
		return Maths::Max(int(next_cast_time) - getGameTime(), 0);
	}

	CBlob@ getEmit(CBlob@ caster)
	{
		return getBlobByNetworkID(caster.get_netid("spellemit_netid"));
	}

	void onCommand(CBlob@ caster, WizardVars@ vars, const int&in cmd, CBitStream@ params) 
	{
		//override me
	}

	void SendCommand(CBlob@ caster, WizardVars@ vars, const int&in cmd, CBitStream@ params) 
	{
		// Supported commands
		// caster.getCommandID("client_spell_command")
		// caster.getCommandID("server_spell_command")

		CBitStream stream;
		stream.write_u8(vars.spell_index);
		stream.write_CBitStream(params);
		caster.SendCommand(cmd, stream);
	}

	void Serialize(CBitStream@ stream)
	{
		stream.write_u32(next_cast_time);
		stream.write_bool(active);
	}

	bool Unserialize(CBitStream@ stream)
	{
		if (!stream.saferead_u32(next_cast_time)) { error("Failed to read next_cast_time [SpellCommon]"); return false; }
		if (!stream.saferead_bool(active)) { error("Failed to read active [SpellCommon]"); return false; }

		return true;
	}


	/// BOTS

	void setBotAimPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		//override me
		caster.setAimPos(pos);
	}

	void setBotStartPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		//override me
	}

	Vec2f getBotStartPos(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		return caster.getAimPos();
	}

	Vec2f getBotMovePos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		//override me
		Navigator navigator(pos);
		navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getVisibleCost };
		navigator.valid_evaluators = { @isInMap, @isOpenSpace };
		return navigator.getBestPositionFromOrigin(30, 30);
	}

	u16 getBotMoveDelay(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		return time_to_cast + 60;
	}

	void onBotStart(CBlob@ caster, WizardVars@ vars)
	{
		//override me
	}

	void onBotTick(CBlob@ caster, WizardVars@ vars)
	{
		//override me
	}

	void onBotComplete(CBlob@ caster, WizardVars@ vars) 
	{
		//override me
	}

	void onBotInterrupted(CBlob@ caster, WizardVars@ vars) 
	{
		//override me
		if (isServer())
		{
			caster.set_u16("brain_movement_delay", 60);
		}
	}

	bool canBotCast(CBlob@ caster, WizardVars@ vars)
	{
		//override me
		return true;
	}
}
