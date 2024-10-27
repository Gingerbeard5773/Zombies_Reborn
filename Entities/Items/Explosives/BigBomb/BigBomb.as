//Gingerbeard @ October 24, 2024

#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 24.0f);
	this.set_f32("explosive_radius", 38.0f);
	this.set_f32("explosive_damage", 9.0f);
	this.set_u8("custom_hitter", Hitters::keg);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.8f);
	this.set_bool("map_damage_raycast", true);
	this.Tag("medium weight");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage >= this.getHealth() || isExplosionHitter(customData) || customData == Hitters::keg)
	{
		this.Tag("exploding");
		this.server_Die();
		return 0.0f;
	}
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.isCollidable() && (!blob.hasTag("player") || blob.hasTag("undead"));
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null ? !doesCollideWithBlob(this, blob) || (blob.isPlatform() && !solid) : !solid) return;
	
	if (blob !is null && blob.getName() == "trampoline") return; //hack

	const f32 vellen = this.getOldVelocity().Length();
	if (vellen >= 8.0f)
	{
		this.Tag("exploding");
		this.server_Die();
	}
}
