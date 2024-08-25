
funcdef void onFireHandle(CBlob@, GunInfo@);
funcdef void onReloadHandle(CBlob@, CBlob@, GunInfo@);

shared class GunInfo
{
	u16 reload_time;
	u16 reload_ready_time;
	
	Vec2f muzzle_offset;
	
	string ammo_name;
	u16 ammo_capacity;
	u16 ammo_count;
	string projectile_name;
	string shoot_sound;

	//u8 fire_interval;
	//u8 fire_interval_timer;
	
	f32 sprite_recoil;
	Vec2f sprite_offset;
	
	f32 bullet_damage;
	f32 bullet_time;
	f32 bullet_speed;
	f32 bullet_spread;
	u8 bullet_amount;

	GunInfo()
	{
		reload_time = 0;
		reload_ready_time = 30;
		
		ammo_name = "";
		ammo_capacity = 1;
		ammo_count = 0;
		projectile_name = "";
		shoot_sound = "";
		
		//fire_interval = 1;
		//fire_interval_timer = 0;
		
		sprite_recoil = 0.0f;
		sprite_offset = Vec2f();
		
		bullet_damage = 1.0f;
		bullet_time = 0.3f;
		bullet_speed = 50.0f;
		bullet_spread = 0.0f;
		bullet_amount = 1;
	}
};

f32 getAimAngle(CBlob@ this, CBlob@ holder)
{
	Vec2f aim_vec = (this.getPosition() - holder.getAimPos());
	aim_vec.Normalize();
	const f32 angle = aim_vec.getAngleDegrees() + (!this.isFacingLeft() ? 180 : 0);
	return -angle;
}
