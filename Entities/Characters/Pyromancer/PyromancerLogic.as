// Pyromancer logic

#include "SpellCommon.as"
#include "Hitters.as"
#include "ParticleTeleport.as"
#include "UndeadTeam.as"
#include "Hitters.as"
#include "GetSurvivors.as"
#include "LootTable.as"
#include "Zombie_Translation.as"
#include "Zombie_GlobalMessagesCommon.as"

const int breakout_time = 30 * 5;

void onInit(CBlob@ this)
{
	Spell@[] pyromancer_spells =
	{
		FireboltSpell(),
		FireballSpell(),
		MagicMissileSpell(),
		IncinerateSpell(),
		EnergyBeamSpell(),
		FirebreathSpell(),
		ChainLightningSpell(),
		NukeSpell(),
		SummonJerrySpell(),
		EnergyBeamStormSpell()
	};

	WizardVars vars(@pyromancer_spells);
	this.set("WizardVars", vars);

	this.Tag("medium weight");

	this.Tag("ignore saw");
	this.Tag("sawed");//hack

	this.set_u8("override head", 176);

	this.set_u8("knocked", 1);
	this.addCommandID("knocked"); //unused atm, only added to stop console spam

	this.server_setTeamNum(getUndeadTeam());
	
	this.SetChatBubbleFont("medium font");

	this.addCommandID("client_teleport");

	this.SetLight(true);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 240, 170, 171));
	
	// Change difficulty depending on player count
	if (isServer())
	{
		CPlayer@[] players; getSurvivors(@players);
		const f32 additional = players.length * 5.0f;
		this.server_SetHealth(this.getInitialHealth() + additional);
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null && !player.isBot())
	{
		this.getBrain().server_SetActive(false);
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch(customData)
	{
		case Hitters::spikes:
		case Hitters::fire:
			damage *= 0.0f;
			break;
	}

	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("ZombieHit");
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_teleport") && isClient())
	{
		Vec2f old_pos, new_pos;
		if (!params.saferead_Vec2f(old_pos)) { error("Failed to read old_pos [PyromancerLogic]"); return; }
		if (!params.saferead_Vec2f(new_pos)) { error("Failed to read new_pos [PyromancerLogic]"); return; }

		this.setPosition(new_pos);

		ParticleTeleport(old_pos);
		ParticleTeleportSparks(old_pos, new_pos);
		ParticleTeleport(new_pos);
	}
}

void onTick(CBlob@ this)
{
	ProcessIntroduction(this);

	if (this.isInInventory())
	{
		BreakoutOfCrate(this);
	}
}

void ProcessIntroduction(CBlob@ this)
{
	if (getGameTime() % 30 != 0) return;

	int intro_time = this.get_u8("introduction_time");
	if (intro_time >= 15) return;
	
	intro_time++;

	this.set_u8("introduction_time", intro_time);
	
	if (intro_time == 15 && isServer())
	{
		server_SendGlobalMessage(getRules(), "PyromancerAttack", 6);
	}

	switch(intro_time)
	{
		case 3:  Chat(this, Translate("Pyromancer0"));  break;
		case 7:  Chat(this, Translate("Pyromancer1"));  break;
		case 12: Chat(this, Translate("Pyromancer2"));  break;
	}
}

void BreakoutOfCrate(CBlob@ this)
{
	if (!isServer()) return;

	CBlob@ inventory_blob = this.getInventoryBlob();
	if (inventory_blob is null) return;
	
	int breakout_delay = this.get_u32("breakout_delay") - 1;
	if (breakout_delay <= 0)
	{
		this.server_Hit(inventory_blob, inventory_blob.getPosition(), Vec2f_zero, 0.3f, Hitters::crush, true);

		breakout_delay = breakout_time;
	}
	this.set_u32("breakout_delay", breakout_delay);
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	Chat(this, Translate("Pyromancer5"));

	this.set_u8("introduction_time", 15);
	this.set_u32("breakout_delay", breakout_time);

	this.doTickScripts = true;
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	Chat(this, Translate("Pyromancer4"));
}

void Chat(CBlob@ this, const string&in text)
{
	this.Chat(text);
}

LootItem@[] pyromancer_loot_table =
{
	LootItem("scroll_clone", 1, 1, 1),
	LootItem("scroll_obliteration", 1, 1, 1),
	LootItem("scroll_time", 1, 1, 1),
	LootItem("scroll_rewind", 1, 1, 1),
	LootItem("scroll_resurgence", 1, 1, 1)
};

void onDie(CBlob@ this)
{
	server_MakeLoot(pyromancer_loot_table, this);
}
