#include "Hitters.as"
#include "WraithCommon.as"

const u32 TIME_TO_ENRAGE = 90 * 30;
const int COINS_ON_DEATH = 20;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("WraithSpawn.ogg");
	sprite.SetEmitSound("DarkWraithChatter.ogg");
	sprite.SetEmitSoundPaused(false);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");
	this.Tag("wraith");

	// explosiveness
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 32.0f);
	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_u8("custom_hitter", 26); //keg
	this.set_string("custom_explosion_sound", "KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.7f);
	this.set_bool("map_damage_raycast", true);
	//

	this.set_s32("auto_enrage_time", TIME_TO_ENRAGE + XORRandom(TIME_TO_ENRAGE / 2));

	this.addCommandID("client_enrage");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("ZombieHit");
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_enrage") && isClient())
	{
		this.set_bool("exploding", true);

		this.getSprite().PlaySound("WraithDie", 1.0f, 0.8f);

		this.SetLight(true);
		this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
		this.SetLightColor(SColor(255, 211, 121, 224));
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("DarkWraithDie");

	if (!this.hasTag("exploding")) return;

	this.getSprite().PlaySound("DarkWraithExplode", 1.0f, 0.9f);

	if (isServer())
	{
		Vec2f pos = this.getPosition();
		for (u8 i = 0; i < 6; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos);
			if (blob is null) continue;

			Vec2f vel = getRandomVelocity(XORRandom(360), 10, 0.0f);
			blob.setVelocity(vel);
			blob.server_SetTimeToDie(8 + XORRandom(4));
		}
	}
}
