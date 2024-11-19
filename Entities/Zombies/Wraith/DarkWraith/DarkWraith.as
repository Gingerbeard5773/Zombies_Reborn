#include "Hitters.as";
#include "WraithCommon.as";

const int COINS_ON_DEATH = 20;

const u32 TIME_TO_ENRAGE_DARK = TIME_TO_ENRAGE * 2.0f;

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

	CRules@ rules = getRules();
	const u16 day_number = rules.get_u16("day_number");
	const u16 player_count = rules.get_u8("survivor player count");
	const u32 difficulty = (day_number * 5) + (player_count * 2);
	const u32 probability = 600 - Maths::Min(difficulty, 600);
	Random rand(this.getNetworkID() + day_number + player_count);
	if (rand.NextRanged(probability) == 0) this.Tag("jerry");
	
	if (this.hasTag("jerry"))
	{
		this.Tag("jerry");
		sprite.SetEmitSound("JerryChatter.ogg");
		sprite.SetEmitSoundPaused(false);
		sprite.ReloadSprite("Jerry.png");
		
		this.Untag("bomberman_style");
		
		this.server_SetHealth(this.getInitialHealth() * 4.0f);
		
		this.SetLight(true);
		this.SetLightRadius(this.get_f32("explosive_radius"));
		this.SetLightColor(SColor(255, 138, 3, 3));
		
		this.setInventoryName("Jerry");
	}
	
	this.addCommandID("enrage_client");
}

void onTick(CBlob@ this)
{
	if (isClient() && this.hasTag("jerry"))
	{
		const f32 time_to_die = this.getTimeToDie();
		if (time_to_die > 0.0f)
		{
			CSprite@ sprite = this.getSprite();
			const f32 currentSpeed = sprite.getEmitSoundSpeed() + 0.01f;
			this.getSprite().SetEmitSoundSpeed(currentSpeed);
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
	
	const bool jerry = this.hasTag("jerry");
	if (jerry)
	{
		switch(customData)
		{
			case Hitters::spikes:
				damage *= 0.25f;
				break;
			case Hitters::arrow:
				damage *= 0.5f;
				break;
		}
	}

	if (customData == Hitters::fire && !jerry)
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

		this.set_bool("exploding", enrage);

		if (enrage)
		{
			const bool jerry = this.hasTag("jerry");
			this.getSprite().PlaySound(jerry ? "JerryIgnite" : "WraithDie", jerry ? 2.5f : 1.0f, 0.8f);

			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
			this.SetLightColor(SColor(255, 211, 121, 224));
			
			if (jerry)
			{
				this.SetLightRadius(this.get_f32("explosive_radius"));
				this.SetLightColor(SColor(255, 200, 20, 20));
			}
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("DarkWraithDie");
	
	if (!this.hasTag("exploding")) return;

	this.getSprite().PlaySound("DarkWraithExplode", 1.0f, 0.9f);

	const bool jerry = this.hasTag("jerry");
	
	if (isClient() && jerry)
	{
		this.getSprite().PlaySound("JerryExplode.ogg", 1.3f, 1.0f);
		Sound::Play("JerryExplodeDistant.ogg");
	}

	if (isServer())
	{
		Vec2f pos = this.getPosition();
		if (jerry)
			server_CreateBlob("nukeexplosion", -1, pos);

		const u8 flame_amount = jerry ? 10 : 6;
		const f32 flame_vel_magnitude = jerry ? 15.0f : 10.0f;
		for (u8 i = 0; i < flame_amount; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos);
			if (blob is null) continue;
			
			Vec2f vel = getRandomVelocity(XORRandom(360), flame_vel_magnitude, 0.0f);
			blob.setVelocity(vel);
			blob.server_SetTimeToDie(8 + XORRandom(4));
		}
	}
}
