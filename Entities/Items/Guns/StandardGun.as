//Gingerbeard @ July 28, 2024
#include "GunCommon.as"

void onInit(CBlob@ this)
{
	// Prevent classes from jabbing n stuff
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null) 
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}

	this.Tag("gun");
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently

	this.addCommandID("shoot client");
	this.addCommandID("shoot server");
}

void onTick(CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();
		if (holder !is null)
		{	
			GunInfo@ gun;
			if (!this.get("gunInfo", @gun)) return;
			
			this.setAngleDegrees(getAimAngle(this, holder));

			ManageGun(this, holder, point, gun);
		}
	}
}

void ManageGun(CBlob@ this, CBlob@ holder, AttachmentPoint@ point, GunInfo@ gun)
{
	const bool ismyplayer = holder.isMyPlayer();

	CSprite@ sprite = this.getSprite();
	sprite.ResetTransform();
	sprite.SetOffset(Vec2f(gun.sprite_recoil, 0) + gun.sprite_offset); //Recoil effect for gun blob

	gun.sprite_recoil = Maths::Lerp(gun.sprite_recoil, 0, 0.45f);
	
	const bool pressed_action1 = point.isKeyPressed(key_action1);
	const bool pressed_action2 = point.isKeyPressed(key_action2);

	if (pressed_action2) //reload
	{
		CInventory@ inv = holder.getInventory();
		if (gun.ammo_count <= 0 && inv !is null && inv.getItem(gun.ammo_name) !is null)
		{
			gun.reload_time++;

			this.setAngleDegrees(30 * (this.isFacingLeft() ? -1 : 1));

			onReloadHandle@ onReload;
			if (this.get("onReload handle", @onReload)) 
			{
				onReload(this, holder, gun);
			}

			if ((gun.reload_time + 50)%75 == 0)
			{
				sprite.PlaySound("thud.ogg");
			}
			if (gun.reload_time >= gun.reload_ready_time)
			{
				sprite.PlaySound("LoadingTick"+(XORRandom(2)+1));
				gun.ammo_count = gun.ammo_capacity;
				gun.reload_time = 0;
				holder.TakeBlob(gun.ammo_name, 1);
			}
		}
	}
	else if (pressed_action1) //fire gun
	{
		if (gun.ammo_count > 0 && ismyplayer)
		{
			gun.ammo_count -= 1; //remove ammo on client to stop multi-fire commands
			ClientFire(this, holder, gun);
		}
	}
	else
	{
		//reset to normal if no actions in progress
		gun.reload_time = Maths::Max(gun.reload_time - 4, 0);
	}

	if (ismyplayer)
	{
		//set cursor
		int frame = 0;
		if (gun.ammo_count > 0)
		{
			frame = 18;
		}
		else if (gun.reload_time > 0)
		{
			frame = int((f32(gun.reload_time) / f32(gun.reload_ready_time)) * 9) * 2;
		}
		this.set_u8("frame", frame);
	}
}

void ClientFire(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	Vec2f pos = this.getPosition();
	Vec2f vel = holder.getAimPos() - pos;

	CBitStream params;
	params.write_Vec2f(pos);
	params.write_Vec2f(vel);
	this.SendCommand(this.getCommandID("shoot server"), params);
}

void CreateBullet(CBlob@ this, CBlob@ holder, GunInfo@ gun, Vec2f&in position, Vec2f&in velocity)
{
	for (u8 i = 0 ; i < gun.bullet_amount; i++)
	{
		CBlob@ projectile = server_CreateBlobNoInit(gun.projectile_name);
		if (projectile !is null)
		{
			projectile.SetDamageOwnerPlayer(holder.getPlayer());
			projectile.set_f32("bullet damage", gun.bullet_damage);
			projectile.set_f32("bullet time", gun.bullet_time);
			projectile.Init();

			projectile.IgnoreCollisionWhileOverlapped(this);
			projectile.server_setTeamNum(holder.getTeamNum());
			projectile.setPosition(position);

			velocity.RotateBy(shotrandom.NextRanged(gun.bullet_spread) * (XORRandom(2) == 0 ? 1 : -1));
			velocity.Normalize();
			velocity *= gun.bullet_speed;

			projectile.setVelocity(velocity);
		}
	}
}

Random shotrandom(0x15125);

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	GunInfo@ gun;
	if (!this.get("gunInfo", @gun)) return;

	if (cmd == this.getCommandID("shoot client") && isClient())
	{
		gun.ammo_count = params.read_u16();

		if (!gun.shoot_sound.isEmpty())
			this.getSprite().PlaySound(gun.shoot_sound);

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
		
		if (!isServer()) //dont repeat on localhost
		{
			onFireHandle@ onFire;
			if (this.get("onFire handle", @onFire)) 
			{
				onFire(this, gun);
			}
		}
	}
	else if (cmd == this.getCommandID("shoot server") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ holder = player.getBlob();
		if (holder is null) return;

		Vec2f pos = params.read_Vec2f();
		Vec2f vel = params.read_Vec2f();

		CreateBullet(this, holder, gun, pos, vel);

		gun.ammo_count = Maths::Max(gun.ammo_count - 1, 0);

		onFireHandle@ onFire;
		if (this.get("onFire handle", @onFire)) 
		{
			onFire(this, gun);
		}
		
		CBitStream stream;
		stream.write_u16(gun.ammo_count); //sync ammo
		this.SendCommand(this.getCommandID("shoot client"), stream);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (!attached.hasTag("weapon cursor") && attached.hasTag("player"))
	{
		attached.getSprite().AddScript("WeaponCursor.as");
		attached.Tag("weapon cursor");
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ params)
{
	GunInfo@ gun;
	if (!this.get("gunInfo", @gun)) return;

	params.write_u16(gun.reload_time);
	params.write_u16(gun.ammo_count);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ params)
{
	GunInfo@ gun;
	if (!this.get("gunInfo", @gun)) return false;
	
	if (!params.saferead_u16(gun.reload_time)) return false;
	if (!params.saferead_u16(gun.ammo_count)) return false;

	return true;
}
