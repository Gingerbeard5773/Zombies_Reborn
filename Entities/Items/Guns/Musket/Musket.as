//Gingerbeard @ July 28, 2024
#include "RunnerCommon.as"
#include "GunCommon.as"
#include "Zombie_Translation.as"

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	this.Tag("medium weight");
	this.getShape().SetOffset(Vec2f(8, 0));

	GunInfo gun;
	gun.reload_ready_time = 125;
	gun.muzzle_offset = Vec2f(22, 2);
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
	
	onFireHandle@ fire_handle = @onFire;
	this.set("onFire handle", @fire_handle);
	
	this.setInventoryName(name(Translate::Musket));
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

	gun.sprite_recoil = 5;

	Vec2f pos = this.getPosition();
	ShakeScreen(150.0f, 1.0f, pos);
	const f32 angle = this.getAngleDegrees() + (this.isFacingLeft() ? 180 : 0);
	Vec2f muzzle = Vec2f(gun.muzzle_offset.x, gun.muzzle_offset.y * (this.isFacingLeft() ? 1 : -1));
	pos += muzzle.RotateBy(angle);

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
