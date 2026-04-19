//Gingerbeard @ April 5, 2026

#include "GunCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	this.Tag("medium weight");
	this.getShape().SetOffset(Vec2f(6, 0));

	this.Tag("gun");
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently

	GunInfo gun;
	gun.muzzle_offset = Vec2f(22, 4);
	gun.ammo_name = "molotov";
	gun.ammo_capacity = 20;
	gun.projectile_name = "flame";
	gun.sprite_offset = this.getSprite().getOffset();
	gun.bullet_speed = 8.0f;
	gun.bullet_spread = 5.0f;
	this.set("gunInfo", @gun);

	this.set_u16("ammo_count", 0);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("flamethrower.ogg");
	sprite.SetEmitSoundPaused(true);

	this.setInventoryName(name(Translate("Flamethrower")));
}

void onTick(CBlob@ this)
{
	if (!this.isAttached()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	GunInfo@ gun;
	if (!this.get("gunInfo", @gun)) return;

	this.setAngleDegrees(getAimAngle(this, holder));

	ManageGun(this, holder, point, gun);
}

void ManageGun(CBlob@ this, CBlob@ holder, AttachmentPoint@ point, GunInfo@ gun)
{
	const bool ismyplayer = holder.isMyPlayer();

	CSprite@ sprite = this.getSprite();
	sprite.ResetTransform();
	sprite.SetOffset(Vec2f(gun.sprite_recoil, 0) + gun.sprite_offset); //Recoil effect for gun blob

	gun.sprite_recoil = Maths::Lerp(gun.sprite_recoil, 0, 0.45f);

	bool firing = false;
	const bool pressed_action1 = point.isKeyPressed(key_action1);

	u16 ammo_count = this.get_u16("ammo_count");

	if (pressed_action1) //fire gun
	{
		CBlob@ ammo_holder = getAmmoHolder(holder, gun);
		if (ammo_count == 0 && ammo_holder !is null)
		{
			sprite.PlaySound("LoadingTick"+(XORRandom(2)+1));

			ammo_holder.TakeBlob(gun.ammo_name, 1);
			ammo_count = gun.ammo_capacity;
		}

		if (ammo_count > 0)
		{
			if (isClient())
			{
				firing = true;

				gun.sprite_recoil = 2;

				ShakeScreen(10.0f, 1.0f, this.getPosition());

				f32 vol = Maths::Min(1.0f, sprite.getEmitSoundVolume() + 0.1f);
				sprite.SetEmitSoundVolume(vol);
				sprite.SetEmitSoundPaused(false);
				
				/*if (holder.isMyPlayer()) //too annoying
				{
					CControls@ controls = getControls();
					Vec2f newMousePos = controls.getMouseScreenPos() + Vec2f(XORRandom(5) - XORRandom(5), XORRandom(5) - XORRandom(5));
					controls.setMousePosition(newMousePos);
				}*/
			}

			if (getGameTime() % 3 == 0)
			{
				ammo_count--;

				CreateBullet(this, holder, gun);
			}
		}

		this.set_u16("ammo_count", ammo_count);
		if (isServer())
		{
			this.Sync("ammo_count", true);
		}
	}
	else
	{
		//reset to normal if no actions in progress
		gun.reload_time = Maths::Max(gun.reload_time - 4, 0);
	}

	if (!firing)
	{
		TurnOffSound(sprite);
	}

	if (ismyplayer)
	{
		//set cursor
		int frame = 0;
		if (ammo_count > 0)
		{
			f32 ratio = f32(ammo_count) / f32(gun.ammo_capacity);
			frame = 1 + Maths::Clamp(Maths::Floor(ratio * 17.0f), 0, 17);
		}

		this.set_u8("frame", frame);
	}
}

void CreateBullet(CBlob@ this, CBlob@ holder, GunInfo@ gun)
{
	if (!isServer()) return;

	Vec2f position = this.getPosition();
	Vec2f velocity = holder.getAimPos() - position;

	const f32 angle = this.getAngleDegrees() + (this.isFacingLeft() ? 180 : 0);
	Vec2f muzzle = Vec2f(gun.muzzle_offset.x, gun.muzzle_offset.y * (this.isFacingLeft() ? 1 : -1));
	position += muzzle.RotateBy(angle);

	CBlob@ projectile = server_CreateBlobNoInit(gun.projectile_name);
	if (projectile !is null)
	{
		projectile.SetDamageOwnerPlayer(holder.getPlayer());
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

void TurnOffSound(CSprite@ sprite)
{
	if (!isClient() || sprite.getEmitSoundPaused()) return;

	sprite.SetEmitSoundVolume(0.1f);
	sprite.SetEmitSoundPaused(true);
	sprite.PlaySound("flamethroweroff.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attachedPoint.SetKeysToTake(key_action1);
	if (attached.getName() != "archer") 
	{
		attachedPoint.SetKeysToTake(key_action1 | key_action2);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	TurnOffSound(this.getSprite());
}
