// scroll script that makes enemies insta gib within some radius

#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), getTranslatedString("Use this to make all visible enemies instantly turn into a pile of gibs."));
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
		bool hit = false;
		u16 killed = 0;
		const u8 team = caller.getTeamNum();
		CBlob@[] blobsInRadius;
		if (getMap().getBlobsInRadius(pos, 500.0f, @blobsInRadius))
		{
			const u16 blobsLength = blobsInRadius.length;
			for (u16 i = 0; i < blobsLength; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b.getTeamNum() == team || !b.hasTag("undead")) continue;

				ParticleZombieLightning(b.getPosition());
				if (isServer())
				{
					caller.server_Hit(b, pos, Vec2f(0, 0), 10.0f, Hitters::suddengib, true);
					
					if (b.getHealth() <= b.get_f32("gib health"))
					{
						killed++;
					}
				}
				hit = true;
			}
		}

		if (!hit) return;

		Statistics::server_Add("scrolls_used", 1, player);
		this.Tag("dead");
		this.server_Die();

		if (killed >= 150)
		{
			Achievement::server_Unlock(Achievement::PureCarnage, player);
		}
	}
}

void onDie(CBlob@ this)
{
	ParticleZombieLightning(this.getPosition());
	Sound::Play("SuddenGib.ogg");
}
