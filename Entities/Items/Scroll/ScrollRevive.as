// scroll script that revives a player within a radius

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_revive");
	this.addCommandID("client_revive");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_bool(false);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_revive"), desc(Translate::ScrollRevive), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_revive") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		if (this.hasTag("dead")) return;
		
		Vec2f[] revived_positions;
		
		bool self_revive;
		if (!params.saferead_bool(self_revive)) return;
		
		if (self_revive) //reviving self
		{
			RevivePlayer(player, caller);
			revived_positions.push_back(caller.getPosition());
		}

		CBlob@[] blobsInRadius;
		getMap().getBlobsInRadius(this.getPosition(), 40.0f, @blobsInRadius);

		const u16 blobsLength = blobsInRadius.length;
		for (u16 i = 0; i < blobsLength; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (!b.hasTag("dead") || b.hasTag("undead") || !b.exists("player_username")) continue;		

			CPlayer@ dead_player = getPlayerByUsername(b.get_string("player_username")); //RunnerDeath.as
			if (dead_player is null || dead_player.getBlob() !is null || dead_player.getTeamNum() != 0) continue;

			RevivePlayer(dead_player, b);
			revived_positions.push_back(b.getPosition());
		}

		const u8 revived_count = revived_positions.length;
		if (revived_count > 0)
		{
			CBitStream stream;
			stream.write_u8(revived_count);
			for (u8 i = 0; i < revived_count; i++)
			{
				stream.write_Vec2f(revived_positions[i]);
			}
			this.SendCommand(this.getCommandID("client_revive"), stream);
			
			this.Tag("dead");
			this.server_Die();
		}
	}
	else if (cmd == this.getCommandID("client_revive") && isClient())
	{
		u8 revived_count;
		if (!params.saferead_u8(revived_count)) return;

		for (u8 i = 0; i < revived_count; i++)
		{
			Vec2f pos;
			if (!params.saferead_Vec2f(pos)) return;

			ParticleZombieLightning(pos);
			Sound::Play("MagicWand.ogg", pos);
			
			for (u8 i = 0; i < 20; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 4, 360.0f);
				ParticleAnimated("HealParticle", pos, vel, float(XORRandom(360)), 1.2f, 4, 0, false);
			}
		}
	}
}

void RevivePlayer(CPlayer@ player, CBlob@ b)
{
	Vec2f bpos = b.getPosition();
	//create new blob for our dead player to use
	CBlob@ newBlob = server_CreateBlob(b.getName(), 0, bpos);
	if (player !is null)
	{
		newBlob.server_SetPlayer(player);
		newBlob.server_SetHealth(newBlob.getInitialHealth() * 2.0f);
	}
	
	//kill dead body
	b.server_Die();
}
