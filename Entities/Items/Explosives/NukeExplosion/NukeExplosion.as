#include "Hitters.as"
#include "Explosion.as"

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

	this.SetLight(true);
	this.SetLightColor(SColor(255, 255, 255, 255));
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;

	const u8 explosions_max = this.get_u8("nuke_explosions_max");
	const u8 boom_count = this.get_u8("boom_count");
	
	if (boom_count < explosions_max)
	{
		DoExplosion(this, boom_count, explosions_max);

		this.set_u8("boom_count", boom_count + 1);
	}
	else
	{
		// End explosion
		this.server_SetTimeToDie(1);
		this.SetLight(false);
		this.Tag("dead");
	}
}

void DoExplosion(CBlob@ this, const u8&in boom_count, const u8&in explosions_max)
{
	const f32 modifier = f32(boom_count) / f32(explosions_max);
	const f32 radius = this.get_f32("nuke_explosion_radius");

	const f32 damage = 16.0f * (1.0f - modifier) * radius;
	this.set_f32("map_damage_radius", 80.0f * modifier * radius);

	// Effects
	ShakeScreen(512, 64, this.getPosition());
	this.SetLightRadius(250.0f * modifier);

	// Base explosion at center
	this.set_Vec2f("explosion_offset", Vec2f(0, 0));
	Explode(this, 128.0f * modifier * radius, damage);

	// Creeping explosion outwards
	Random rand(this.getNetworkID() + boom_count);
	for (u8 i = 0; i < 2; i++)
	{
		const f32 x = (100 - int(rand.NextRanged(200))) / 50.0f;
		const f32 y = (100 - int(rand.NextRanged(200))) / 400.0f;
		this.set_Vec2f("explosion_offset", Vec2f(x, y) * 128.0f * modifier * radius);
		Explode(this, 128.0f * modifier * radius, damage);
	}
}
