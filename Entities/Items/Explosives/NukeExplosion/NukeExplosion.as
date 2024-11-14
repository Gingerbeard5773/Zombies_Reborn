#include "Hitters.as";
#include "Explosion.as";

const u8 explosions_max = 5;

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;
	this.Tag("map_damage_ground");
	this.set_string("custom_explosion_sound", "");
	
	this.getShape().SetStatic(true);
	
	if (this.isOnScreen())
	{
		SetScreenFlash(255, 255, 255, 255);
	}
	
	Vec2f screenPos = getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos());
	this.getSprite().PlaySound("JerryExplode.ogg", 1.3f, 1.0f);
	Sound::Play("JerryExplodeDistant.ogg", screenPos, 1.0f, 1.0f);
	
	this.SetLight(true);
	this.SetLightColor(SColor(255, 255, 255, 255));
	this.SetLightRadius(1024.5f);
}

void DoExplosion(CBlob@ this)
{
	ShakeScreen(512, 64, this.getPosition());
	// SetScreenFlash(255 * (1.00f - (f32(this.get_u8("boom_count")) / f32(explosions_max))), 255, 255, 255);
	
	const f32 modifier = f32(this.get_u8("boom_count")) / f32(explosions_max);
	
	this.set_f32("map_damage_radius", 80.0f * modifier);
	
	this.set_Vec2f("explosion_offset", Vec2f(0, 0));
	Explode(this, 128.0f * modifier, 16.0f * (1 - modifier));
	
	Random rand(this.getNetworkID() + this.get_u8("boom_count"));
	
	for (u8 i = 0; i < 2; i++)
	{
		this.set_Vec2f("explosion_offset", Vec2f((100 - int(rand.NextRanged(200))) / 50.0f, (100 - int(rand.NextRanged(200))) / 400.0f) * 128 * modifier);
		Explode(this, 128.0f * modifier, 16.0f * (1 - modifier));
	}
}

void onTick(CBlob@ this)
{
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

	if (getGameTime() % 2 == 0 && this.get_u8("boom_count") < explosions_max)
	{
		DoExplosion(this);
		this.set_u8("boom_count", this.get_u8("boom_count") + 1);
		
		const f32 modifier = 1.00f - (f32(this.get_u8("boom_count")) / f32(explosions_max));
		this.SetLightRadius(1024.5f * modifier);
	}
}
