// scroll script that teleports the player

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("teleport");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_netid(caller.getNetworkID());
	params.write_Vec2f(caller.getAimPos());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("teleport"), ZombieDesc::scroll_teleport, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("teleport"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;
		
		Vec2f aim = params.read_Vec2f();
		Vec2f pos = this.getPosition();
		if ((aim - pos).Length() < 100.0f) return;
		
		CMap@ map = getMap();
		TileType t = map.getTile(aim).type;
		if (map.isTileSolid(t)) return;
		
		if (isClient())
		{
			//effects
			for (u8 i = 0; i < 5; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
				ParticleAnimated("MediumSteam", pos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
			}
			
			ParticleZombieLightning(pos);
			ParticleZombieLightning(aim);
			
			Sound::Play("Respawn.ogg", pos, 3.5f);
		}
		
		if (caller.isMyPlayer())
		{
			caller.setPosition(aim);
		}
		
		this.server_Die();
	}
}
