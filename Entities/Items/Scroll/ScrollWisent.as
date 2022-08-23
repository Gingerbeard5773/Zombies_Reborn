// scroll script that spawns a bison

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("spawn bison");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	
	CMap@ map = getMap();
	const int rand = XORRandom(300) - 150;
	const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
	Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -16);

	CBitStream params;
	params.write_Vec2f(spawnPos);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("spawn bison"), ZombieDesc::scroll_wisent, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("spawn bison"))
	{
		Vec2f spawnPos = params.read_Vec2f();
		
		if (isClient())
		{
			//effects
			for (u8 i = 0; i < 20; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
				ParticleAnimated("MediumSteam", spawnPos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
			}
			
			Sound::Play("Bomb.ogg", spawnPos);
			Sound::Play("MagicWand.ogg", spawnPos, 1.0f, 0.8f);
		}

		if (isServer())
		{
			server_CreateBlob("bison", -1, spawnPos);
			this.server_Die();
		}
	}
}
