//Gingerbeard @ October 24, 2024

#include "Hitters.as"
#include "FireParticle.as"

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

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.getCurrentScript().tickIfTag = "ballistic";
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
	const string name = blob.getName();
	if (name == "log" || blob.exists("eat sound")) return false;

	if (blob.hasTag("material") && !blob.hasTag("explosive")) return false;

	const bool willExplode = this.getTeamNum() == blob.getTeamNum() ? blob.getShape().isStatic() : true; 
	if (blob.isCollidable() && willExplode)
	{
		CPlayer@ player = blob.getPlayer();
		if (player !is null && player is this.getDamageOwnerPlayer()) return false;

		return true;
	}
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null ? !doesCollideWithBlob(this, blob) || (blob.isPlatform() && !solid) : !solid) return;
	
	if (blob !is null && blob.getName() == "trampoline") return; //hack

	const f32 vellen = this.getOldVelocity().Length();
	if (vellen >= 8.0f || this.hasTag("ballistic"))
	{
		this.Tag("exploding");
		this.server_Die();
	}
}

void onTick(CBlob@ this)
{
	this.Tag("no pickup");

	const f32 angle = -this.getVelocity().Angle() - 90;
	this.setAngleDegrees(angle);

	if (getGameTime() % 3 == 0)
	{
		Vec2f offset = Vec2f(0.0f, -10.0f);
		offset.RotateBy(angle);
		makeFireParticle(this.getPosition() + offset, 4);
	}
}
