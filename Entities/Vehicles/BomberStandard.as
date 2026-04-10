//common bomber functionality

#include "VehicleCommon.as"
#include "ActivationThrowCommon.as"
#include "Hitters.as"
#include "Zombie_TechnologyCommon.as"
#include "Zombie_AchievementsCommon.as"

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
		HandleBombing(this, blob);
	}
	
	const bool up = flyer.isKeyPressed(key_action1);
	const bool down = flyer.isKeyPressed(key_action2) || flyer.isKeyPressed(key_down);
	
	CSprite@ sprite = this.getSprite();
	f32 volume = Maths::Clamp(Maths::Lerp(sprite.getEmitSoundVolume(), up ? 1.0f : (down ? 0.0f : 0.3f), (1.0f / 30) * 2.5f), 0.0f, 1.0f);
	if (this.isOnGround()) volume *= 0.95f;
	sprite.SetEmitSoundVolume(volume);
	
	Vehicle_FlyerControlsCustom(this, blob, flyer, v);

	// calculate altitude force dropoff
	const f32 maximum_altitude = -80.0f;
	const f32 altitude = this.getPosition().y;
	const f32 factor = 1.0f - Maths::Clamp((maximum_altitude - altitude) / 2000.0f, 0.0f, 1.0f);

	const f32 fly_amount = this.get_f32("fly_amount");

	this.AddForce(Vec2f(0, v.fly_speed * fly_amount * factor));

	if (blob is null && fly_amount > 0.0f)
	{
		this.set_f32("fly_amount", fly_amount * 0.998f);
	}
}

void Vehicle_FlyerControlsCustom(CBlob@ this, CBlob@ blob, AttachmentPoint@ ap, VehicleInfo@ v)
{
	f32 moveForce = v.move_speed;
	const f32 turnSpeed = v.turn_speed;
	const Vec2f vel = this.getVelocity();
	f32 fly_amount = this.get_f32("fly_amount");
	Vec2f force;
	
	const bool upgrade = hasTech(Tech::FlightTuning);

	// fly up/down
	const bool up = ap.isKeyPressed(key_action1);
	const bool down = ap.isKeyPressed(key_action2) || ap.isKeyPressed(key_down);
	if (up || down)
	{
		const f32 flight = 0.3f * (upgrade ? 1.25f : 1.0f);
		if (up)
		{
			fly_amount = Maths::Min(fly_amount + flight / getTicksASecond(), 1.0f);
		}
		else
		{
			fly_amount = Maths::Max(fly_amount - flight / getTicksASecond(), 0.5f);
		}

		this.set_f32("fly_amount", fly_amount);
	}

	// fly left/right
	const bool left = ap.isKeyPressed(key_left);
	const bool right = ap.isKeyPressed(key_right);
	if (left)
	{
		force.x -= moveForce;
		if (vel.x < -turnSpeed)
		{
			this.SetFacingLeft(true);
		}
	}

	if (right)
	{
		force.x += moveForce;
		if (vel.x > turnSpeed)
		{
			this.SetFacingLeft(false);
		}
	}

	if (left || right)
	{
		if (upgrade) force *= 1.25f;
		this.AddForce(force);
	}
}

void HandleBombing(CBlob@ this, CBlob@ pilot)
{
	CInventory@ inv = this.getInventory();
	const int items_count = inv.getItemsCount();
	if (items_count <= 0) return;
	
	for (u16 i = 0; i < items_count; i++)
	{
		CBlob@ item = inv.getItem(i);
		const string item_name = item.getName();
		if (item_name == "mat_arrows") continue;
		
		this.getSprite().PlaySound("bridge_open", 1.0f, 1.0f);
		this.set_u32("last_drop", getGameTime() + 30);

		if (!isServer()) return;

		if (item_name == "mat_bombs")
		{
			CBlob@ blob = server_CreateBlob("bomb", this.getTeamNum(), this.getPosition() + Vec2f(0, 12));
			if (blob !is null)
			{
				item.server_Die();
			}
		}
		else if (item_name == "mat_waterbombs")
		{
			CBlob@ blob = server_CreateBlob("waterbomb", this.getTeamNum(), this.getPosition() + Vec2f(0, 12));
			if (blob !is null)
			{
				blob.set_f32("map_damage_ratio", 0.0f);
				blob.set_f32("explosive_damage", 0.0f);
				blob.set_f32("explosive_radius", 92.0f);
				blob.set_bool("map_damage_raycast", false);
				blob.set_string("custom_explosion_sound", "/GlassBreak");
				blob.set_u8("custom_hitter", Hitters::water);
				blob.Tag("splash ray cast");
				item.server_Die();
			}
		}
		else
		{
			if (item_name == "bigbomb")
			{
				CPlayer@ player = pilot.getPlayer();
				if (player !is null)
				{
					Achievement::server_Unlock(Achievement::Bombardier, player);
				}
			}

			this.server_PutOutInventory(item);
			item.setPosition(this.getPosition() + Vec2f(0, 12));
			if (item.hasTag("activatable"))
			{
				server_Activate(item);
			}
		}
		break;
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
