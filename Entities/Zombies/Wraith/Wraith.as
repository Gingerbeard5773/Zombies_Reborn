const u8 TIME_TO_EXPLODE = 5; //seconds
const s32 TIME_TO_ENRAGE = 45 * 30;

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
}

void onTick(CBlob@ this)
{
	if (this.hasTag("enraged"))
	{
		if (!this.hasTag("exploding"))
		{
			this.Tag("exploding");
			
			//start kill timer
			this.server_SetTimeToDie(TIME_TO_EXPLODE);
			
			this.getSprite().PlaySound("/WraithDie");
			
			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
			this.SetLightColor(SColor(255, 211, 121, 224));
		}
		
		if (isClient())
		{
			if (XORRandom(128) == 0)
			{
				this.getSprite().PlaySound("/WraithDie");
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}
	else if (customData >= 3 && customData <= 5 && this.hasTag("enraged")) //water hitters
	{
		//reset if we got watered
		
		this.getBrain().SetTarget(null);
		this.set_u8("brain_delay", 250);
		this.Untag("enraged");
		this.Untag("exploding");
		
		//stop kill timer
		this.server_SetTimeToDie(-1);
		
		this.SetLight(false);
		
		if (isClient())
		{
			this.getSprite().PlaySound("Steam.ogg");
			
			//steam particles
			for (u8 i = 0; i < 5; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
				ParticleAnimated("MediumSteam", this.getPosition(), vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
			}
		}
	}

	return damage;
}
