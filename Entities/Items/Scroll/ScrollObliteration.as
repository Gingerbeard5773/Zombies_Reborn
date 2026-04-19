// scroll script that kills everything

#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), desc(Translate("ScrollObliteration")));
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

		Vec2f pos = this.getPosition();
		const u8 team = caller.getTeamNum();
		bool acted = false;

		CBlob@[] blobs;
		getBlobs(@blobs);

		const int blobs_length = blobs.length;
		for (int i = 0; i < blobs_length; i++)
		{
			CBlob@ b = blobs[i];
			if (b.getTeamNum() == team) continue;

			if (!b.hasTag("player") && !b.hasTag("undead")) continue;

			caller.server_Hit(b, pos, Vec2f(0, 0), 100.0f, Hitters::suddengib, true);

			acted = true;
		}

		if (acted)
		{
			Statistics::server_Add("scrolls_used", 1, player);
			this.Tag("dead");
			this.server_Die();

			this.SendCommand(this.getCommandID("client_execute_spell"));
		}
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Sound::Play("SpellMagic7.ogg");
		SetScreenFlash(255, 255, 255, 255, 5.0f);
	}
}
