// Pyromancer logic

#include "SpellCommon.as"
#include "Hitters.as"
#include "ParticleTeleport.as"
#include "UndeadTeam.as"

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

	this.addCommandID("client_teleport");

	this.SetLight(true);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 240, 170, 171));
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null && !player.isBot())
	{
		this.getBrain().server_SetActive(false);
	}
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
