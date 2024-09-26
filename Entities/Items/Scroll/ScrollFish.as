// scroll script that spawns a shark

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
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollFish);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		this.Tag("dead");
		
		CMap@ map = getMap();
		const int rand = XORRandom(300) - 150;
		const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
		Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -8);

		server_CreateBlob("shark", -1, spawnPos);
		this.server_Die();
		
		CBitStream stream;
		stream.write_Vec2f(spawnPos);
		this.SendCommand(this.getCommandID("client_execute_spell"), stream);
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Vec2f spawnPos = params.read_Vec2f();
		Sound::Play("MagicWand.ogg", spawnPos, 1.5f, 1.2f);
		
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
	}
}
