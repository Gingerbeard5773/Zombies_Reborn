// scroll script that revives a player within a radius

#include "GenericButtonCommon.as";
#include "RespawnCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_revive");
	this.addCommandID("client_revive");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_netid(caller.getNetworkID());
	params.write_bool(false);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_revive"), "Use this near a dead body to ressurect them.", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_revive") && isServer())
	{
		Vec2f pos = this.getPosition();

		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;
		
		Vec2f[] revived_positions;
		
		if (params.read_bool()) //reviving self
		{
			CPlayer@ player = caller.getPlayer();
			if (player !is null)
			{
				RevivePlayer(player, caller);
				revived_positions.push_back(caller.getPosition());
				this.server_Die();
			}
		}
		else
		{
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
						if ((player is null || player.getBlob() !is null) && b.getName() != "migrant") continue;
						
						RevivePlayer(player, b);
						revived_positions.push_back(b.getPosition());
						this.server_Die();
					}
				}
			}
		}
		const u8 revived_count = revived_positions.length;
		if (revived_count > 0)
		{
			CBitStream bs;
			bs.write_u8(revived_count);
			for (u16 i = 0; i < revived_count; i++)
			{
				bs.write_Vec2f(revived_positions[i]);
			}
			this.SendCommand(this.getCommandID("client_revive"), bs);
		}
	}
	else if (cmd == this.getCommandID("client_revive") && isClient())
	{
		const u8 revived_count = params.read_u8();
		for (u8 i = 0; i < revived_count; i++)
		{
			Vec2f bpos = params.read_Vec2f();
			ParticleZombieLightning(bpos);
			Sound::Play("MagicWand.ogg", bpos);
			
			for (u8 i = 0; i < 20; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 4, 360.0f);
				ParticleAnimated("HealParticle", bpos, vel, float(XORRandom(360)), 1.2f, 4, 0, false);
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

		//remove respawn
		Respawn[]@ respawns;
		if (getRules().get("respawns", @respawns))
		{
			for (u8 i = 0; i < respawns.length; i++)
			{
				if (respawns[i].username != player.getUsername()) continue;
				
				respawns.erase(i);
				break;
			}
		}
	}
	
	//kill dead body
	b.server_Die();
}
