// Swing Door logic

#include "Hitters.as"
#include "FireCommon.as"
#include "DoorCommon.as"

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.getSprite().getConsts().accurateLighting = true;

	this.set_s16(burn_duration , 300);
	//transfer fire to underlying tiles
	this.Tag(spread_fire_tag);

	// this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 0;

	//block knight sword
	this.Tag("blocks sword");

	// disgusting HACK
	// for DefaultNoBuild.as
	if (this.getName() == "stone_door")
	{
		this.set_TileType("background tile", CMap::tile_castle_back);

		if (isServer())
		{
			dictionary harvest;
			harvest.set('mat_stone', 10);
			this.set('harvest', harvest);
		}
	}
	else if (this.getName() == "wooden_door")
	{
		this.set_TileType("background tile", CMap::tile_wood_back);

		if (isServer())
		{
			dictionary harvest;
			harvest.set('mat_wood', 10);
			this.set('harvest', harvest);
		}
	}
	this.Tag("door");
	this.Tag("blocks water");
	this.Tag("explosion always teamkill"); // ignore 'no teamkill' for explosives
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	if (!this.hasTag("set door closed"))
	{
		this.getSprite().PlaySound("/build_door.ogg");

		const u16 count = this.getTouchingCount();
		for (u16 i = 0; i < count; i++)
		{
			CBlob@ blob = this.getTouchingByIndex(i);
			if (blob.isCollidable() && !blob.getShape().isStatic())
			{
				OpenDoor(this, blob);
				break;
			}
		}
	}
}

void setOpen(CBlob@ this, bool open, bool faceLeft = false)
{
	CSprite@ sprite = this.getSprite();
	if (open)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;
		
		const u16 count = this.getTouchingCount();
		for (u16 i = 0; i < count; i++)
		{
			this.getTouchingByIndex(i).AddForce(Vec2f_zero); // forces collision checks again
		}

		this.getCurrentScript().tickFrequency = 3;
		sprite.SetFacingLeft(faceLeft);   // swing left or right
		Sound::Play("/DoorOpen.ogg", this.getPosition());
	}
	else
	{
		sprite.SetZ(100.0f);
		sprite.SetAnimation("close");
		this.getShape().getConsts().collidable = true;
		this.getCurrentScript().tickFrequency = 0;
		Sound::Play("/DoorClose.ogg", this.getPosition());
	}
}

void onTick(CBlob@ this)
{
	if (!isOpen(this)) //open it
	{
		const u16 count = this.getTouchingCount();
		for (u16 i = 0; i < count; i++)
		{
			CBlob@ blob = this.getTouchingByIndex(i);
			if (canOpenDoor(this, blob))
			{
				OpenDoor(this, blob);
				break;
			}
		}
	}
	else if (canClose(this)) // close it
	{
		setOpen(this, false);
	}
}

bool canClose(CBlob@ this)
{
	const u16 count = this.getTouchingCount();
	for (u16 i = 0; i < count; i++)
	{
		CBlob@ blob = this.getTouchingByIndex(i);
		if (blob.isCollidable())
		{
			return false;
		}
	}
	return true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		this.getCurrentScript().tickFrequency = 3;
		if (!isOpen(this) && canOpenDoor(this, blob)) 
		{
			OpenDoor(this, blob, true);
		}
	}
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	if (blob !is null && canClose(this))
	{
		if (isOpen(this))
		{
			setOpen(this, false);
		}
		this.getCurrentScript().tickFrequency = 0;
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::builder:
			damage *= 2.0f;
			break;
		case Hitters::sword:
			damage *= 1.5f;
			break;
		case Hitters::bomb:
			damage *= 1.4f;
			if (hitterBlob.getTeamNum() == this.getTeamNum())
				damage *= 0.65f;
			break;
		case Hitters::drill:
			damage *= 2.0f;
			break;
		default:
			break;
	}

	if (this.hasTag("will_soon_collapse"))
	{
		damage *= 1.25f;
	}

	return damage;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	MakeDamageFrame(this, this.getHealth() > oldHealth);
}

void MakeDamageFrame(CBlob@ this, bool repaired = false)
{
	CSprite@ sprite = this.getSprite();
	const f32 hp = this.getHealth();
	const f32 full_hp = this.getInitialHealth();

	Animation@ destruction_anim = sprite.getAnimation("destruction");
	if (destruction_anim !is null)
	{
		const int frame_count = destruction_anim.getFramesCount();
		const int frame = frame_count - frame_count * (hp / full_hp);
		destruction_anim.frame = frame;
		
		Animation@ close_anim = sprite.getAnimation("close");
		if (close_anim !is null)
		{
			close_anim.RemoveFrame(close_anim.getFramesCount() - 1);
			close_anim.AddFrame(destruction_anim.getFrame(frame));
		}

		if (repaired)
		{
			sprite.PlaySound("/build_door.ogg");
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !isOpen(this) && !canOpenDoor(this, blob);
}

void OpenDoor(CBlob@ this, CBlob@ blob, bool open = true)
{
	Vec2f direction = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
	const bool faceLeft = ((this.getPosition() - blob.getPosition()) * direction) < 0.0f;
	setOpen(this, open, faceLeft);
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	const bool closed = !isOpen(this) && this.getShape().isStatic();
	stream.write_bool(closed);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	bool closed;
	if (!stream.saferead_bool(closed)) return false;

	MakeDamageFrame(this);

	if (closed)
	{
		this.Tag("set door closed");
		this.getSprite().SetAnimation("close");
	}
	
	return true;
}
