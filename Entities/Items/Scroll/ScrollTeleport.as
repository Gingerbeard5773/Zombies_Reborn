// scroll script that teleports the player

#include "GenericButtonCommon.as"
#include "ParticleTeleport.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Teleport, desc(Translate::ScrollTeleport));
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

		if (this.hasTag("dead")) return;

		Vec2f aim;
		if (!params.saferead_Vec2f(aim)) return;
		
		Vec2f pos = this.getPosition();
		if ((aim - pos).Length() < 100.0f) return;

		CMap@ map = getMap();
		TileType t = map.getTile(aim).type;
		if (map.isTileSolid(t)) return;

		Statistics::server_Add("scrolls_used", 1, player);

		AttemptAchievement(caller, player);

		caller.server_DetachFromAll();
		caller.setPosition(aim);

		this.Tag("dead");
		this.server_Die();

		CBitStream stream;
		stream.write_netid(caller.getNetworkID());
		stream.write_Vec2f(aim);
		this.SendCommand(this.getCommandID("client_execute_spell"), stream);
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ caller = getBlobByNetworkID(netid);
		if (caller is null) return;

		Vec2f aim;
		if (!params.saferead_Vec2f(aim)) return;

		caller.setPosition(aim);

		Vec2f pos = this.getPosition();

		ParticleTeleport(pos);
		ParticleTeleportSparks(pos, aim);
		ParticleTeleport(aim);
	}
}

/// Achievement

void AttemptAchievement(CBlob@ caller, CPlayer@ player)
{
	AttachmentPoint@[] aps;
	caller.getAttachmentPoints(@aps);
	for (int i = 0; i < aps.length; i++)
	{
		CBlob@ blob = aps[i].getOccupied();
		if (blob !is null && blob.getName() == "skelepede")
		{
			Achievement::server_Unlock(Achievement::NarrowEscape, player);
			return;
		}
	}
}
