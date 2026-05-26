// Teleportation Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"
#include "ParticleTeleport.as"

class TeleportSpell : Spell
{
	TeleportSpell()
	{
		name = "Teleport";
		result_name = "teleport";
		icon_name = "$orb$";
		tier = SpellTier::TierI;
		time_to_cast = 15;
		cooldown_time = 0;
		auto_cast = false;
		fragile = false;
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (caster.isMyPlayer())
		{
			client_Teleport(caster, vars, caster.getAimPos());
		}

		if (isServer() && (caster.getPlayer() is null || caster.isBot()))
		{
			server_Teleport(caster, vars, caster.getAimPos());
		}
	}
	
	void client_Teleport(CBlob@ caster, WizardVars@ vars, Vec2f aim_pos)
	{
		CMap@ map = getMap();
		if (map.isTileSolid(map.getTile(aim_pos))) return;

		CBitStream stream;
		stream.write_Vec2f(aim_pos);
		SendCommand(caster, vars, caster.getCommandID("server_spell_command"), stream);
	}

	void server_Teleport(CBlob@ caster, WizardVars@ vars, Vec2f aim_pos)
	{
		CMap@ map = getMap();
		if (map.isTileSolid(map.getTile(aim_pos))) return;

		Vec2f old_pos = caster.getPosition();

		caster.server_DetachFromAll();
		caster.setPosition(aim_pos);
		caster.setVelocity(Vec2f_zero);

		CBitStream stream;
		stream.write_Vec2f(aim_pos);
		stream.write_Vec2f(old_pos);
		SendCommand(caster, vars, caster.getCommandID("client_spell_command"), stream);
	}

	void onCommand(CBlob@ caster, WizardVars@ vars, const int&in cmd, CBitStream@ params) 
	{
		if (cmd == caster.getCommandID("server_spell_command") && isServer())
		{
			Vec2f aim_pos;
			if (!params.saferead_Vec2f(aim_pos)) { error("Failed to read aim_pos [0] [TeleportSpell]"); return; }

			server_Teleport(caster, vars, aim_pos);
		}
		else if (cmd == caster.getCommandID("client_spell_command") && isClient())
		{
			Vec2f aim_pos;
			if (!params.saferead_Vec2f(aim_pos)) { error("Failed to read aim_pos [1] [TeleportSpell]"); return; }

			Vec2f old_pos;
			if (!params.saferead_Vec2f(old_pos)) { error("Failed to read old_pos [TeleportSpell]"); return; }

			caster.setPosition(aim_pos);
			caster.setVelocity(Vec2f_zero);

			ParticleTeleport(old_pos);
			ParticleTeleportSparks(old_pos, aim_pos);
			ParticleTeleport(aim_pos);
		}
	}
}
