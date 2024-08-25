//Gingerbeard @ July 28, 2024
#include "RunnerCommon.as"
#include "GunCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("medium weight");
	this.getShape().SetOffset(Vec2f(8, 0));

	GunInfo gun;
	gun.reload_ready_time = 125;
	gun.muzzle_offset = Vec2f(22, -2);
	gun.ammo_name = "mat_musketballs";
	gun.ammo_capacity = 1;
	gun.projectile_name = "bullet";
	gun.shoot_sound = "MusketFire.ogg";
	gun.sprite_offset = this.getSprite().getOffset();
	gun.bullet_damage = 9.0f;
	gun.bullet_time = 0.8f;
	gun.bullet_speed = 50.0f;
	gun.bullet_spread = 1.0f;
	gun.bullet_amount = 1;
	this.set("gunInfo", @gun);

	onReloadHandle@ reload_handle = @onReload;
	this.set("onReload handle", @reload_handle);
}

void onReload(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	RunnerMoveVars@ moveVars;
	if (!holder.get("moveVars", @moveVars)) return;

	//slow down player
	moveVars.walkFactor *= 0.25f;
	moveVars.jumpFactor *= 0.50f;
	moveVars.canVault = false;
}
