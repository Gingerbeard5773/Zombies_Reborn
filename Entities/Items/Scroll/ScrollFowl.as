// scroll script that spawns chickens

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

const u8 chicken_num = 3;

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollFowl);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		this.Tag("dead");

		CBitStream stream;
		for (u8 i = 0; i < chicken_num; ++i)
		{
			CMap@ map = getMap();
			const int rand = XORRandom(300) - 150;
			const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
			Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -16);

			stream.write_Vec2f(spawnPos);
			server_CreateBlob("chicken", -1, spawnPos);
		}
		
		this.server_Die();
		
		this.SendCommand(this.getCommandID("client_execute_spell"), stream);
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Sound::Play("MagicWand.ogg", this.getPosition(), 1.0f, 0.9f);

		for (u8 i = 0; i < chicken_num; ++i)
		{
			Vec2f spawnPos = params.read_Vec2f();
			for (u8 q = 0; q < 5; q++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
				ParticleAnimated("FireFlash", spawnPos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
			}
		}
	}
}
