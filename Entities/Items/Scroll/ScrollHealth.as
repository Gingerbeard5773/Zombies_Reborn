// scroll script that over-heals players in a radius

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollHealth);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		if (this.hasTag("dead")) return;

		u16[] healed;
		const u8 team = caller.getTeamNum();
		CBlob@[] blobsInRadius;
		getMap().getBlobsInRadius(this.getPosition(), 200.0f, @blobsInRadius);

		for (u16 i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b.getTeamNum() != team || b.hasTag("undead")) continue;
			
			if (b.hasTag("player") || b.hasTag("migrant"))
			{
				const f32 heal = b.getHealth() + b.getInitialHealth() * 2.0f;
				b.server_SetHealth(heal);
				healed.push_back(b.getNetworkID());
			}
		}

		const u8 healed_count = healed.length;
		if (healed_count > 0)
		{
			CBitStream stream;
			stream.write_u16(healed_count);
			for (u16 i = 0; i < healed_count; i++)
			{
				stream.write_netid(healed[i]);
			}
			this.SendCommand(this.getCommandID("client_execute_spell"), stream);
			
			this.Tag("dead");
			this.server_Die();
		}
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		const u8 healed_count = params.read_u16();
		for (u8 i = 0; i < healed_count; i++)
		{
			CBlob@ healed = getBlobByNetworkID(params.read_netid());
			if (healed is null) continue;

			Vec2f pos = healed.getPosition();
			Sound::Play("MagicWand.ogg", pos);
			
			if (healed.isMyPlayer())
			{
				SetScreenFlash(30, 50, 200, 100, 0.75f);
			}
			
			
			for (u8 i = 0; i < 20; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 4, 360.0f);
				ParticleAnimated("HealParticle", pos, vel, float(XORRandom(360)), 1.2f, 4, 0, false);
			}
		}
	}
}

void onDie(CBlob@ this)
{
	Sound::Play("MagicWand.ogg", this.getPosition());
}
