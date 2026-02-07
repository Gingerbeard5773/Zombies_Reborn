//Gingerbeard @ July 28, 2024
#include "RunnerCommon.as"
#include "GunCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	this.Tag("medium weight");
	this.getShape().SetOffset(Vec2f(6, 0));

	GunInfo gun;
	gun.reload_ready_time = 55;
	gun.muzzle_offset = Vec2f(22, -2);
	gun.ammo_name = "mat_musketballs";
	gun.ammo_capacity = 2;
	gun.projectile_name = "bullet";
	gun.shoot_sound = "Shotgun1.ogg";
	gun.sprite_offset = this.getSprite().getOffset();
	gun.bullet_damage = 2.3f;
	gun.bullet_time = 0.6f;
	gun.bullet_speed = 35.0f;
	gun.bullet_spread = 5.0f;
	gun.bullet_amount = 4;
	this.set("gunInfo", @gun);

	onReloadHandle@ reload_handle = @onReload;
	this.set("onReload handle", @reload_handle);
	
	onFireHandle@ fire_handle = @onFire;
	this.set("onFire handle", @fire_handle);
	
	this.setInventoryName(name(Translate::Shotgun));
}

void onReload(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	this.setAngleDegrees(30 * (this.isFacingLeft() ? -1 : 1));
	
	if ((gun.reload_time + 50)%75 == 0)
	{
		this.getSprite().PlaySound("thud.ogg");
	}

	RunnerMoveVars@ moveVars;
	if (!holder.get("moveVars", @moveVars)) return;

	//slow down player
	moveVars.walkFactor *= 0.25f;
	moveVars.jumpFactor *= 0.50f;
	moveVars.canVault = false;
}

void onFire(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	if (!isClient()) return;
	
	if (holder.isMyPlayer())
	{
		Achievement::client_Unlock(Achievement::CrowdControl);
	}

	gun.sprite_recoil = 5;

	Vec2f pos = this.getPosition();
	ShakeScreen(150.0f, 1.0f, pos);
	const f32 angle = this.getAngleDegrees() + (this.isFacingLeft() ? 180 : 0);
	pos += Vec2f(0, gun.muzzle_offset.y) + Vec2f(gun.muzzle_offset.x, 0).RotateBy(angle);
	
	//muzzle flash
	ParticleAnimated("MuzzleFlash.png", pos, Vec2f(), angle, 1.0f, 3, 0.0f, true);
	
	for (u8 i = 0; i < 5; i++)
	{
		Vec2f vel = getRandomVelocity(angle, -8.0f + XORRandom(700)/100, 30);

		CParticle@ p = ParticleAnimated("GenericSmoke.png", pos, vel, XORRandom(360), 1.0f, 6 + XORRandom(8), 0.0f, true);
		if (p !is null)
		{
			p.scale = 0.6f + shotrandom.NextFloat()*0.5f;
			p.damping = 0.85f;
		}
	}
}
