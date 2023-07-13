// scroll script that spawns chickens

#include "GenericButtonCommon.as";

const u8 chicken_num = 3;

void onInit(CBlob@ this)
{
	this.addCommandID("spawn chickens");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	
	CBitStream params;
	for (u8 i = 0; i < chicken_num; ++i)
	{
		CMap@ map = getMap();
		const int rand = XORRandom(300) - 150;
		const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
		Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -16);

		params.write_Vec2f(spawnPos);
	}
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("spawn chickens"), "Use this to summon a flock of chickens.", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("spawn chickens"))
	{
		for (u8 i = 0; i < chicken_num; ++i)
		{
			Vec2f spawnPos = params.read_Vec2f();
			
			if (isClient())
			{
				//effects
				for (u8 i = 0; i < 5; i++)
				{
					Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
					ParticleAnimated("FireFlash", spawnPos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
				}
			}
			
			if (isServer())
			{
				server_CreateBlob("chicken", -1, spawnPos);
			}
		}
		
		Sound::Play("MagicWand.ogg", this.getPosition(), 1.0f, 0.9f);
		this.server_Die();
	}
}
