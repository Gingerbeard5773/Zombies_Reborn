// scroll script that teleports the player

#include "GenericButtonCommon.as";
#include "ParticleTeleport.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, "Use this to teleport to the area you are pointing to.");
}

void Callback_Spell(CBlob@ this, CBlob@ caller)
{
	Vec2f aim = caller.getAimPos();
	Vec2f pos = this.getPosition();
	if ((aim - pos).Length() < 100.0f) return;
	
	CMap@ map = getMap();
	TileType t = map.getTile(aim).type;
	if (map.isTileSolid(t)) return;
	
	if (caller.isMyPlayer())
	{
		caller.setPosition(aim);
	}
	
	ParticleTeleport(pos);
	ParticleZombieLightning(aim);

	this.SendCommand(this.getCommandID("server_execute_spell"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{	
		this.server_Die();
	}
}
