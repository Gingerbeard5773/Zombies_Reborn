// scroll script that teleports the player

#include "GenericButtonCommon.as";
#include "ParticleTeleport.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Teleport, Translate::ScrollTeleport);
}

void Callback_Teleport(CBlob@ this, CBlob@ caller)
{
	Vec2f aim = caller.getAimPos();
	CBitStream stream;
	stream.write_Vec2f(aim);
	this.SendCommand(this.getCommandID("server_execute_spell"), stream);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		Vec2f aim = params.read_Vec2f();
		
		Vec2f pos = this.getPosition();
		if ((aim - pos).Length() < 100.0f) return;
		
		CMap@ map = getMap();
		TileType t = map.getTile(aim).type;
		if (map.isTileSolid(t)) return;
		
		if (this.hasTag("dead")) return;
		this.Tag("dead");
		
		caller.setPosition(aim);

		this.server_Die();
		
		CBitStream stream;
		stream.write_netid(caller.getNetworkID());
		stream.write_Vec2f(aim);
		this.SendCommand(this.getCommandID("client_execute_spell"), stream);
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;

		Vec2f aim = params.read_Vec2f();
		caller.setPosition(aim);

		ParticleTeleport(this.getPosition());
		ParticleZombieLightning(aim);
	}
}
