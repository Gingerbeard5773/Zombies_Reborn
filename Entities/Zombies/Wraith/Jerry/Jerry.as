#include "Hitters.as"
#include "WraithCommon.as"

const int COINS_ON_DEATH = 20;

const u32 TIME_TO_ENRAGE_DARK = TIME_TO_ENRAGE * 2.0f;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("WraithSpawn.ogg");
	sprite.SetEmitSound("JerryChatter.ogg");
	sprite.SetEmitSoundPaused(false);

	this.getShape().SetRotationsAllowed(false);
	this.getBrain().server_SetActive(true);
	
	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");
	this.Tag("wraith");

	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_u8("custom_hitter", 26); //keg
	this.set_string("custom_explosion_sound", "KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.7f);
	this.set_bool("map_damage_raycast", true);

	this.set_s32("auto_enrage_time", getGameTime() + TIME_TO_ENRAGE_DARK + XORRandom(TIME_TO_ENRAGE_DARK / 2));

	this.SetLight(true);
	this.SetLightRadius(this.get_f32("explosive_radius"));
	this.SetLightColor(SColor(255, 138, 3, 3));

	this.addCommandID("enrage_client");
}

void onTick(CBlob@ this)
{
	if (isClient())
	{
		const f32 time_to_die = this.getTimeToDie();
		if (time_to_die > 0.0f)
		{
			CSprite@ sprite = this.getSprite();
			const f32 currentSpeed = sprite.getEmitSoundSpeed() + 0.01f;
			sprite.SetEmitSoundSpeed(currentSpeed);
		}
	}

	if (isServer())
	{
		const s32 auto_explode_timer = this.get_s32("auto_enrage_time") - getGameTime();
		if (this.isKeyPressed(key_action1) || auto_explode_timer < 0)
		{
			server_SetEnraged(this, true, false, false);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("ZombieHit");
	}

	switch(customData)
	{
		case Hitters::spikes:
			damage *= 0.25f;
			break;
		case Hitters::arrow:
			damage *= 0.5f;
			break;
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

		this.set_bool("exploding", enrage);

		if (enrage)
		{
			this.getSprite().PlaySound("JerryIgnite", 2.5f , 0.8f);

			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius"));
			this.SetLightColor(SColor(255, 200, 20, 20));
		}
	}
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("exploding"))
	{
		this.getSprite().PlaySound("DarkWraithDie");
		return;
	}

	if (isClient())
	{
		this.getSprite().PlaySound("DarkWraithExplode", 1.0f, 0.9f);
		this.getSprite().PlaySound("JerryExplode.ogg", 1.3f, 1.0f);
		Sound::Play("JerryExplodeDistant.ogg");
	}

	if (isServer())
	{
		Vec2f pos = this.getPosition();

		server_CreateBlob("nukeexplosion", -1, pos);

		for (u8 i = 0; i < 10; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos);
			if (blob is null) continue;
			
			Vec2f vel = getRandomVelocity(XORRandom(360), 15.0f, 0.0f);
			blob.setVelocity(vel);
			blob.server_SetTimeToDie(8 + XORRandom(4));
		}
	}
}
