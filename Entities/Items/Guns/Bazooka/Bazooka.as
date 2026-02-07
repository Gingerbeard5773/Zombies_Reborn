//Gingerbeard @ Jan 20, 2026
#include "RunnerCommon.as"
#include "GunCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	this.Tag("medium weight");

	GunInfo gun;
	gun.reload_ready_time = 65;
	gun.muzzle_offset = Vec2f(22, -1);
	gun.ammo_name = "bigbomb";
	gun.ammo_capacity = 1;
	gun.projectile_name = "bigbomb";
	gun.shoot_sound = "BazookaShoot.ogg";
	gun.sprite_offset = this.getSprite().getOffset();
	gun.bullet_damage = 9.0f;
	gun.bullet_time = 0.8f;
	gun.bullet_speed = 15.0f;
	gun.bullet_spread = 3.0f;
	gun.bullet_amount = 1;
	this.set("gunInfo", @gun);

	onReloadHandle@ reload_handle = @onReload;
	this.set("onReload handle", @reload_handle);
	
	onFireHandle@ fire_handle = @onFire;
	this.set("onFire handle", @fire_handle);
	
	onProjectileHandle@ projectile_handle = @onProjectile;
	this.set("onProjectile handle", @projectile_handle);
	
	this.setInventoryName(name(Translate::Bazooka));
	
	this.getCurrentScript().tickFrequency = 3;
}

void onReload(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	if (gun.reload_time >= gun.reload_ready_time)
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
		Achievement::client_Unlock(Achievement::PayloadDelivered);
	}

	gun.sprite_recoil = 2;

	Vec2f pos = this.getPosition();
	ShakeScreen(150.0f, 1.0f, pos);
	const f32 angle = this.getAngleDegrees() + (this.isFacingLeft() ? 180 : 0);
	Vec2f front_pos = pos + Vec2f(14, 0).RotateBy(angle);
	Vec2f back_pos = pos - Vec2f(14, 0).RotateBy(angle);

	//muzzle flash
	ParticleAnimated("MuzzleFlash.png", front_pos, Vec2f(), angle, 1.0f, 3, 0.0f, true);
	ParticleAnimated("MuzzleFlash.png", back_pos, Vec2f(), angle+180, 1.0f, 3, 0.0f, true);

	for (u8 i = 0; i < 4; i++)
	{
		Vec2f vel = getRandomVelocity(angle, -8.0f + XORRandom(700)/100, 30);

		CParticle@ p = ParticleAnimated("GenericSmoke.png", front_pos, vel, XORRandom(360), 1.0f, 6 + XORRandom(8), 0.0f, true);
		if (p !is null)
		{
			p.scale = 0.6f + shotrandom.NextFloat()*0.5f;
			p.damping = 0.85f;
		}
	}
}

void onProjectile(CBlob@ this, CBlob@ projectile, GunInfo@ gun)
{
	projectile.Tag("ballistic");
}

void onTick(CBlob@ this)
{
	GunInfo@ gun;
	if (!this.get("gunInfo", @gun)) return;

	const u8 frame = gun.ammo_count > 0 ? 1 : 0;
	this.getSprite().SetFrame(gun.ammo_count > 0 ? 1 : 0);
	this.SetInventoryIcon("Bazooka", frame, Vec2f(32, 13));
}
