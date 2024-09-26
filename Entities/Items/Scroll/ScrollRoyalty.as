// scroll script that spawns a geti

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollRoyalty);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		this.Tag("dead");

		server_CreateBlob("princess", XORRandom(7), this.getPosition());
		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	Sound::Play("MigrantSayHello.ogg", pos);
	Sound::Play("AchievementUnlocked.ogg", pos, 2.0f);
}
