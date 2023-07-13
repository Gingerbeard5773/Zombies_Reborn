// scroll script that spawns a geti

#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("spawn geti");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_u8(caller.getTeamNum());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("spawn geti"), "Use this to summon a geti.", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("spawn geti"))
	{
		const u8 team = params.read_u8();
		
		u8 rand_team = XORRandom(7);
		while(rand_team == team)
		{
			rand_team = XORRandom(7);
		}
		
		Vec2f pos = this.getPosition();
		
		if (isClient())
		{
			//effects
			Sound::Play("MigrantSayHello.ogg", pos);
			Sound::Play("AchievementUnlocked.ogg", pos, 2.0f);
		}

		if (isServer())
		{
			server_CreateBlob("princess", rand_team, pos);
			this.server_Die();
		}
	}
}
