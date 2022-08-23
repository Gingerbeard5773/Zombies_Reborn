// scroll script that revives a player within a radius

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("revive");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_netid(caller.getNetworkID());
	params.write_bool(false);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("revive"), ZombieDesc::scroll_revive, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("revive"))
	{
		Vec2f pos = this.getPosition();

		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;
		
		if (params.read_bool()) //reviving self
		{
			CPlayer@ player = caller.getPlayer();
			if (player !is null)
			{
				RevivePlayer(player, caller);
				this.server_Die();
			}
			return;
		}
		
		CBlob@[] blobsInRadius;
		if (getMap().getBlobsInRadius(pos, 40.0f, @blobsInRadius))
		{
			const u16 blobsLength = blobsInRadius.length;
			for (u16 i = 0; i < blobsLength; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b.hasTag("dead") && !b.hasTag("undead"))
				{
					CPlayer@ player = getPlayerByUsername(b.get_string("player_username")); //RunnerDeath.as
					if (player is null || player.getBlob() !is null) continue;
					
					RevivePlayer(player, b);
					this.server_Die();
					
					break;
				}
			}
		}
	}
}

void RevivePlayer(CPlayer@ player, CBlob@ b)
{
	Vec2f bpos = b.getPosition();
	
	if (isClient())
	{
		//effects
		ParticleZombieLightning(bpos);
		Sound::Play("MagicWand.ogg", bpos);
		
		for (u8 i = 0; i < 20; i++)
		{
			Vec2f vel = getRandomVelocity(-90.0f, 4, 360.0f);
			ParticleAnimated("HealParticle", bpos, vel, float(XORRandom(360)), 1.2f, 4, 0, false);
		}
	}
	
	if (isServer())
	{
		//remove respawn at Zombie_Respawning.as
		CRules@ rules = getRules();
		if (rules.hasCommandID("remove respawn"))
		{
			CBitStream params;
			params.write_string(player.getUsername());
			rules.SendCommand(rules.getCommandID("remove respawn"), params);
		}
		
		//create new blob for our dead player to use
		CBlob@ newBlob = server_CreateBlob(b.getName(), 0, bpos);
		newBlob.server_SetPlayer(player);
		
		//kill dead body
		b.server_Die();
	}
}
