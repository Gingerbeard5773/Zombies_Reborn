#include "Hitters.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;
	this.Tag("map_damage_ground");
	this.set_string("custom_explosion_sound", "");
	if (!this.exists("nuke_explosions_max"))
		this.set_u8("nuke_explosions_max", 5);
	if (!this.exists("nuke_explosion_radius"))
		this.set_f32("nuke_explosion_radius", 1.0f);
		
	this.set_bool("explosive_teamkill", true);
	
	this.getShape().SetStatic(true);
	
	if (this.isOnScreen())
	{
		SetScreenFlash(255, 255, 255, 255);
	}
	
	this.SetLight(true);
	this.SetLightColor(SColor(255, 255, 255, 255));
	this.SetLightRadius(1024.5f);
}

void DoExplosion(CBlob@ this)
{
	const u8 explosions_max = this.get_u8("nuke_explosions_max");
	ShakeScreen(512, 64, this.getPosition());

	const f32 modifier = f32(this.get_u8("boom_count")) / f32(explosions_max);
	const f32 radius = this.get_f32("nuke_explosion_radius");
	this.set_f32("map_damage_radius", 80.0f * modifier * radius);
	
	this.set_Vec2f("explosion_offset", Vec2f(0, 0));
	Explode(this, 128.0f * modifier * radius, 16.0f * (1 - modifier) * radius);
	
	Random rand(this.getNetworkID() + this.get_u8("boom_count"));
	
	for (u8 i = 0; i < 2; i++)
	{
		this.set_Vec2f("explosion_offset", Vec2f((100 - int(rand.NextRanged(200))) / 50.0f, (100 - int(rand.NextRanged(200))) / 400.0f) * 128 * modifier * radius);
		Explode(this, 128.0f * modifier * radius, 16.0f * (1 - modifier) * radius);
	}
}

void onTick(CBlob@ this)
{
	const u8 explosions_max = this.get_u8("nuke_explosions_max");
	if (this.get_u8("boom_count") >= explosions_max) 
	{
		if (!this.hasTag("dead"))
		{
			this.server_SetTimeToDie(1);
			this.SetLight(false);
			this.Tag("dead");
		}
	}

	if (this.hasTag("dead")) return;

	if (this.get_u8("boom_count") < explosions_max)
	{
		DoExplosion(this);
		this.set_u8("boom_count", this.get_u8("boom_count") + 1);
		
		const f32 modifier = 1.00f - (f32(this.get_u8("boom_count")) / f32(explosions_max));
		this.SetLightRadius(1024.5f * modifier);
	}
}
