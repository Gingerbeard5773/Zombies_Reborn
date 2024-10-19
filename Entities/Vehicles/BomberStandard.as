//common bomber functionality

#include "VehicleCommon.as"
#include "ActivationThrowCommon.as"

void onTick(CBlob@ this)
{
	if (this.getHealth() > 1.0f)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;
		
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSound("BomberLoop.ogg");
		sprite.SetEmitSoundPaused(false);

		Vehicle_BomberControls(this, v);
	}
	else
	{
		this.server_DetachAll();
		this.setAngleDegrees(this.getAngleDegrees() + (this.isFacingLeft() ? 1 : -1));
		if (this.isOnGround() || this.isInWater())
		{
			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
		else
		{
			if (getGameTime() % 30 == 0)
				this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 0.05f, 0, true);
		}
	}
}

void Vehicle_BomberControls(CBlob@ this, VehicleInfo@ v)
{
	AttachmentPoint@ flyer = this.getAttachments().getAttachmentPointByName("FLYER");
	if (flyer is null) return;

	CBlob@ blob = flyer.getOccupied();
	
	// get out of seat
	if (isServer() && flyer.isKeyJustPressed(key_up) && blob !is null)
	{
		this.server_DetachFrom(blob);
		return;
	}

	//Bombing
	if (flyer.isKeyPressed(key_action3) && this.get_u32("last_drop") < getGameTime())
	{
		HandleBombing(this);
	}
	
	const bool up = flyer.isKeyPressed(key_action1);
	const bool down = flyer.isKeyPressed(key_action2) || flyer.isKeyPressed(key_down);
	
	CSprite@ sprite = this.getSprite();
	f32 volume = Maths::Clamp(Maths::Lerp(sprite.getEmitSoundVolume(), up ? 1.0f : (down ? 0.0f : 0.3f), (1.0f / 30) * 2.5f), 0.0f, 1.0f);
	if (this.isOnGround()) volume *= 0.95f;
	sprite.SetEmitSoundVolume(volume);
	
	Vehicle_FlyerControls(this, blob, flyer, v);
	
	this.AddForce(Vec2f(0, v.fly_speed * v.fly_amount));
	
	if (blob is null && v.fly_amount > 0.0f) v.fly_amount *= 0.998f;
}

void HandleBombing(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	if (inv.getItemsCount() <= 0) return;

	this.getSprite().PlaySound("bridge_open", 1.0f, 1.0f);
	this.set_u32("last_drop", getGameTime() + 30);

	if (isServer())
	{
		CBlob@ item = inv.getItem(0);
		if (item.getName() == "mat_bombs")
		{
			CBlob@ blob = server_CreateBlob("bomb", this.getTeamNum(), this.getPosition() + Vec2f(0, 12));
			if (blob !is null)
			{
				item.server_Die();
			}
		}
		else
		{
			this.server_PutOutInventory(item);
			item.setPosition(this.getPosition() + Vec2f(0, 12));
			if (item.hasTag("activatable"))
			{
				server_Activate(item);
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{	
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	// jump out
	if (detached.hasTag("player") && attachedPoint.socket)
	{
		detached.setPosition(detached.getPosition() + Vec2f(0.0f, -4.0f));
		detached.setVelocity(this.getVelocity() + v.out_vel);
		detached.IgnoreCollisionWhileOverlapped(null);
		this.IgnoreCollisionWhileOverlapped(null);
	}
}

///NETWORKING

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	stream.write_f32(v.fly_amount);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))                return true;
	if (!stream.saferead_f32(v.fly_amount))          return false;
	return true;
}
