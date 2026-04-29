#include "Hitters.as"
#include "WraithCommon.as"

const u32 TIME_TO_ENRAGE = 45 * 30;
const int COINS_ON_DEATH = 10;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("WraithSpawn.ogg");
	sprite.SetEmitSound("WraithFly.ogg");
	sprite.SetEmitSoundPaused(false);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");
	this.Tag("wraith");

	// explosiveness
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 18.0f);
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

void onTick(CBlob@ this)
{
	if (isClient() && this.hasTag("exploding") && XORRandom(128) == 0)
	{
		this.getSprite().PlaySound("/WraithDie");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_enrage") && isClient())
	{
		this.set_bool("exploding", true);

		this.getSprite().PlaySound("/WraithDie");

		this.SetLight(true);
		this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
		this.SetLightColor(SColor(255, 211, 121, 224));
	}
}
