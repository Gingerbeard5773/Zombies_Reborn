#include "Hitters.as";
#include "WraithCommon.as";

const int COINS_ON_DEATH = 20;

const u32 TIME_TO_ENRAGE_DARK = TIME_TO_ENRAGE * 2.0f;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32("brain_target_rad", 512.0f);

	this.getSprite().PlaySound("WraithSpawn.ogg");

	this.getSprite().SetEmitSound("DarkWraithChatter.ogg");
	this.getSprite().SetEmitSoundPaused(false);
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);
	
	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");

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
	this.set_s32("auto_enrage_time", getGameTime() + TIME_TO_ENRAGE_DARK + XORRandom(TIME_TO_ENRAGE_DARK / 2));
	//
	
	this.addCommandID("enrage_client");
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	//player functionality
	CPlayer@ player = this.getPlayer();
	if (player is null) return;

	const s32 auto_explode_timer = this.get_s32("auto_enrage_time") - getGameTime();
	const u8 delay = this.get_u8("brain_delay");
	if ((this.isKeyPressed(key_action1) && delay == 0 && !this.hasTag("exploding")) || auto_explode_timer < 0)
	{
		server_SetEnraged(this, true, false, false);
	}
	this.set_u8("brain_delay", Maths::Max(0, delay - 1));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("ZombieHit");
	}
	
	if (customData == Hitters::fire)
	{
		server_SetEnraged(this);
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("enrage_client") && isClient())
	{
		bool enrage, stun;
		if (!params.saferead_bool(enrage)) return;
		if (!params.saferead_bool(stun)) return;

		if (enrage)
		{
			this.getSprite().PlaySound("WraithDie", 1.0f, 0.8f);

			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
			this.SetLightColor(SColor(255, 211, 121, 224));
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("DarkWraithDie");
	
	if (this.hasTag("exploding"))
	{
		this.getSprite().PlaySound("DarkWraithExplode", 1.0f, 0.9f);

		Vec2f pos = this.getPosition();
		for (int i = 0; i < 6; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos);
			if (blob is null) continue;
			
			Vec2f vel = getRandomVelocity(XORRandom(360), 10.0f, 0.0f);
			blob.setVelocity(vel);
			blob.server_SetTimeToDie(5 + XORRandom(3));
		}
	}
}
