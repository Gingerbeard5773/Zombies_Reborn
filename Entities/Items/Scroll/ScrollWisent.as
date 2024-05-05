// scroll script that spawns a bison

#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, "Use this to summon a bison.");
}

void Callback_Spell(CBlob@ this, CBlob@ caller)
{
	CMap@ map = getMap();
	const int rand = XORRandom(300) - 150;
	const f32 posX = this.getPosition().x + rand + 25 * (rand > 0 ? 1 : -1);
	Vec2f spawnPos = Vec2f(posX, map.getLandYAtX(posX / map.tilesize) * map.tilesize) + Vec2f(0, -16);

	for (u8 i = 0; i < 20; i++)
	{
		Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
		ParticleAnimated("MediumSteam", spawnPos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
	}
	
	Sound::Play("Bomb.ogg", spawnPos);
	Sound::Play("MagicWand.ogg", spawnPos, 1.0f, 0.8f);

	CBitStream params;
	params.write_Vec2f(spawnPos);
	this.SendCommand(this.getCommandID("server_execute_spell"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		Vec2f spawnPos = params.read_Vec2f();
		server_CreateBlob("bison", -1, spawnPos);
		this.server_Die();
	}
}
