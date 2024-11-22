#include "VehicleCommon.as"
#include "GenericButtonCommon.as"
#include "AssignWorkerCommon.as"
#include "Zombie_TechnologyCommon.as"

// Light Ballista logic

const f32 projectile_speed = 25.0f;

class LightBallistaInfo : VehicleInfo
{
	void onFire(CBlob@ this, CBlob@ bullet, const u16 &in fired_charge)
	{
		if (bullet !is null)
		{
			const f32 sign = this.isFacingLeft() ? -1 : 1;
			const f32 angle = wep_angle * sign;
			Vec2f vel = Vec2f(projectile_speed * sign, 0).RotateBy(angle);
			vel *= hasTech(Tech::TorsionWinch) ? 1.4f : 1.0f;
			bullet.setVelocity(vel);

			if (getCurrentAmmo().ammo_name == "mat_bomb_bolts")
			{
				bullet.Tag("bomb ammo");
				bullet.Sync("bomb ammo", true);
			}
		}
	}
}

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              0.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false,  // inventory access
	              LightBallistaInfo()
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_AddAmmo(this, v,
	                    90, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_bolts", // bullet ammo config name
	                    "Ballista Bolts", // name for ammo selection
	                    "ballista_bolt", // bullet config name
	                    "CatapultFire", // fire sound
	                    "EmptyFire", // empty fire sound
	                    Vec2f(-4, -8) //fire position offset
	                   );

	// explosive bolt ammo
	Vehicle_AddAmmo(this, v,
	                    90, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_bomb_bolts", // bullet ammo config name
	                    "Ballista Shells", // name for ammo selection
	                    "ballista_bolt", // bullet config name
	                    "CatapultFire", // fire sound
	                    "EmptyFire", // empty fire sound
	                    Vec2f(-4, -8) //fire position offset
	                   );

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-20.0f);
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 48, 22);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		int[] frames = { 0, 1 };
		anim.AddFrames(frames);
		arm.SetOffset(Vec2f(-1, -12));
		arm.SetRelativeZ(1.0f);
	}

	this.getShape().SetRotationsAllowed(false);

	string[] autograb_blobs = {"mat_bolts", "mat_bomb_bolts"};
	this.set("autograb blobs", autograb_blobs);

	this.set_bool("facing", true);
	
	this.Tag("heavy weight");
	this.Tag("ignore_arrow");

	// auto-load on creation
	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_bolts");
		if (ammo !is null && !this.server_PutInInventory(ammo))
		{
			ammo.server_Die();
		}
	}
	
	addOnAssignWorker(this, @onAssignWorker);
	addOnUnassignWorker(this, @onUnassignWorker);
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = v.wep_angle;
	const bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (gunner !is null && gunner.getOccupied() !is null)
	{
		CBlob@ operator = gunner.getOccupied();
		gunner.offsetZ = 5.0f;
		Vec2f aimpos = operator.getPlayer() is null ? operator.getAimPos() : gunner.getAimPos();
		Vec2f aim_vec = gunner.getPosition() - aimpos;

		if (this.isAttached())
		{
			if (facing_left) { aim_vec.x = -aim_vec.x; }
			angle = (-(aim_vec).getAngle() + 180.0f);
		}
		else
		{
			if ((!facing_left && aim_vec.x < 0) ||
			        (facing_left && aim_vec.x > 0))
			{
				if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

				angle = (-(aim_vec).getAngle() + 180.0f);
				angle = Maths::Max(-40.0f, Maths::Min(angle , 40.0f));
			}
			else
			{
				this.SetFacingLeft(!facing_left);
			}
		}
	}

	return angle;
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.get_bool("facing") != this.isFacingLeft())
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		const f32 angle = getAimAngle(this, v);
		v.wep_angle = angle;

		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
		if (arm !is null)
		{
			const f32 sign = sprite.isFacingLeft() ? -1 : 1;
			const f32 rotation = angle * sign - this.getAngleDegrees();

			arm.ResetTransform();
			arm.RotateBy(rotation, Vec2f(0.0f, 6.0f));
		}

		Vehicle_LightBallistaControls(this, v);
		
	}
	this.set_bool("facing", this.isFacingLeft());
}

void Vehicle_LightBallistaControls(CBlob@ this, VehicleInfo@ v)
{
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
	CBlob@ blob = ap.getOccupied();
	if (blob is null) return;
	
	// get out of seat
	if (isServer() && ap.isKeyJustPressed(key_up))
	{
		this.server_DetachFrom(blob);
		return;
	}
	
	if (blob.isMyPlayer() && ap.isKeyJustPressed(key_inventory) && v.ammo_types.size() > 1)
	{
		this.SendCommand(this.getCommandID("swap_ammo"));
	}
	
	//allow non-players to shoot vehicle weapons
	const bool isBot = blob.getPlayer() is null;
	const bool press_action1 = isBot ? blob.isKeyPressed(key_action1) : ap.isKeyPressed(key_action1);
	if (isServer() && press_action1 && v.canFire())
	{
		v.getCurrentAmmo().fire_delay = hasTech(Tech::SeigeCrank) ? 65 : 90;

		CBitStream bt;
		bt.write_u16(blob.getNetworkID());
		bt.write_u16(v.charge);
		this.SendCommand(this.getCommandID("fire client"), bt);

		Fire(this, v, blob, v.charge);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!AssignWorkerButton(this, caller))
	{
		UnassignWorkerButton(this, caller, Vec2f(0, -8));
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!attachedPoint.socket) return;

	this.SetDamageOwnerPlayer(attached.getDamageOwnerPlayer());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob, "PASSENGER");
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.isCollidable() && blob.getShape().isStatic();
}

//auto grab ammunition from carrier vehicle
void onInventoryQuantityChange(CBlob@ this, CBlob@ blob, int oldQuantity)
{
	if (!isServer()) return;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PASSENGER");
	if (ap is null) return;
	
	CBlob@ vehicle = ap.getOccupied();
	if (vehicle is null) return;
	
	CInventory@ inv = vehicle.getInventory();
	if (inv is null) return;
	
	string[] autograb_blobs;
	if (!this.get("autograb blobs", autograb_blobs)) return;

	const u16 itemsCount = inv.getItemsCount();
	for (u16 i = 0; i < itemsCount; i++)
	{
		CBlob@ b = inv.getItem(i);
		if (autograb_blobs.find(b.getName()) != -1 && !this.getInventory().isFull())
		{
			this.server_PutInInventory(b);
			break;
		}
	}
}

void onAssignWorker(CBlob@ this, CBlob@ worker)
{
	AttachmentPoint@ gun = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (gun !is null && gun.getOccupied() is null)
	{
		this.server_AttachTo(worker, @gun);
	}
}

void onUnassignWorker(CBlob@ this, CBlob@ worker)
{
	this.server_DetachFrom(worker);
}
