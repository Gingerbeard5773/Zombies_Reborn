// scroll script that respawns all players

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
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), desc(Translate::ScrollResurgence));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (this.hasTag("dead")) return;

		CRules@ rules = getRules();
		dictionary@ respawns;
		if (!getRules().get("respawns", @respawns)) return;

		int respawned_count = 0;

		for (int i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null || p.getBlob() !is null || p.getTeamNum() != player.getTeamNum()) continue;

			respawns.set(p.getUsername(), 0);

			rules.set_u32("client respawn time", 0);
			rules.SyncToPlayer("client respawn time", p);

			respawned_count++;
		}

		if (respawned_count > 0)
		{
			Statistics::server_Add("scrolls_used", 1, player);
			this.Tag("dead");
			this.server_Die();
			
			CBitStream stream;
			stream.write_s32(respawned_count);

			this.SendCommand(this.getCommandID("client_execute_spell"), stream);
		}
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		int respawned_count;
		if (!params.saferead_s32(respawned_count)) return;

		Vec2f pos = this.getPosition();
		const f32 radius = 16.0f;

		for (int i = 0; i < respawned_count; ++i)
		{
			f32 angle = (360.0f * i) / respawned_count;
			Vec2f offset(radius, 0);
			offset.RotateBy(angle);
			
			if (respawned_count == 1) offset = Vec2f_zero;

			CParticle@ p = ParticleAnimated("FireFlash.png", pos + offset, offset / 16.0f, 0, 1.0f, 2, 0.0f, true);
			if (p !is null)
			{
				p.Z = 750.0f;
			}
		}
		
		Sound::Play("SpellMagic2.ogg");
	}
}
