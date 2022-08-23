// scroll script that spawns a shark

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("spawn shark");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	
	CMap@ map = getMap();
	const int rand = XORRandom(300) - 150;
	const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
	Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -8);

	CBitStream params;
	params.write_Vec2f(spawnPos);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("spawn shark"), ZombieDesc::scroll_fish, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("spawn shark"))
	{
		Vec2f spawnPos = params.read_Vec2f();
		
		if (isClient())
		{
			//effects
			CMap@ map = getMap();
			const int radius = 5;
			const f32 radsq = radius * 8 * radius * 8;

			for (int x_step = -radius; x_step < radius; ++x_step)
			{
				for (int y_step = -radius; y_step < radius; ++y_step)
				{
					Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
					if (off.LengthSquared() > radsq) continue;

					Vec2f tpos = spawnPos + off;
					map.SplashEffect(tpos, Vec2f(0, 10), 8.0f);
				}
			}
			
			Sound::Play("MagicWand.ogg", spawnPos, 1.5f, 1.2f);
		}
		
		if (isServer())
		{
			server_CreateBlob("shark", -1, spawnPos);
			this.server_Die();
		}
	}
}
