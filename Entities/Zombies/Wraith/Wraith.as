#include "Hitters.as";
#include "WraithCommon.as";

const int COINS_ON_DEATH = 10;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32("brain_target_rad", 512.0f);

	this.getSprite().PlaySound("WraithSpawn.ogg");

	this.getSprite().SetEmitSound("WraithFly.ogg");
	this.getSprite().SetEmitSoundPaused(false);
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);
	
	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");

	// explosiveness
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 18.0f);
	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_u8("custom_hitter", 26); //keg
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.7f);
	this.set_bool("map_damage_raycast", true);
	this.set_s32("auto_enrage_time", getGameTime() + TIME_TO_ENRAGE + XORRandom(TIME_TO_ENRAGE / 2));
	//

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
	
	this.addCommandID("enrage_client");
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		//player functionality
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{	
			const s32 auto_explode_timer = this.get_s32("auto_enrage_time") - getGameTime();
			const u8 delay = this.get_u8("brain_delay");
			if ((this.isKeyPressed(key_action1) && delay == 0 && !this.hasTag("exploding")) || auto_explode_timer < 0)
			{
				server_SetEnraged(this);
			}
			this.set_u8("brain_delay", Maths::Max(0, delay - 1));
		}
	}
	
	if (isClient() && this.hasTag("exploding") && XORRandom(128) == 0)
	{
		this.getSprite().PlaySound("/WraithDie");
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer())
	{
		CCamera@ cam = getCamera();
		if (cam !is null)
		{
			cam.targetDistance = Maths::Min(1.0f, cam.targetDistance);
		}
		Sound::Play("switch.ogg");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}
	
	if (customData == Hitters::fire)
	{
		server_SetEnraged(this);
	}
	else if (isWaterHitter(customData) && this.hasTag("exploding"))
	{
		server_SetEnraged(this, false);
	}
	else if (this.getPlayer() !is null && customData == Hitters::suicide)
	{
		server_SetEnraged(this);
		return 0.0f; //don't allow insta explode
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("enrage_client") && isClient())
	{
		const bool enrage = params.read_bool();
		if (enrage)
		{
			this.getSprite().PlaySound("/WraithDie");

			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
			this.SetLightColor(SColor(255, 211, 121, 224));
		}
		else
		{
			this.SetLight(false);
			this.getSprite().PlaySound("Steam.ogg");
			
			//steam particles
			for (u8 i = 0; i < 5; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
				ParticleAnimated("MediumSteam", this.getPosition(), vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
			}
		}
	}
}
