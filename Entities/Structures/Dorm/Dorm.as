// Dorm

#include "Requirements.as"
#include "ShopCommon.as"
#include "MigrantCommon.as"
#include "GenericButtonCommon.as"

const f32 heal_amount = 0.25f;
const u8 heal_rate = 30;

void onInit(CBlob@ this)
{
	this.set_s32("gold building amount", 25);
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("respawn"); //allow players to use as respawn point
	
	this.addCommandID("rest");

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(2, 2));
	this.set_string("shop description", "Dormitory");
	this.set_u8("shop icon", 11);
	this.Tag(SHOP_AUTOCLOSE);

	{
		ShopItem@ s = addShopItem(this, "Worker", "$worker_migrant$", "migrant", "Recruit a worker for your needs.");
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 35);
	}

	this.SetLightRadius(60.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		this.getSprite().PlaySound("MigrantSayHello.ogg");
	}
	else if (cmd == this.getCommandID("rest") && isServer())
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller !is null)
		{
			if (this.getDistanceTo(caller) > 40) return;

			AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
			if (bed !is null && bedAvailable(this))
			{
				caller.server_DetachFromAll();
				this.server_AttachTo(caller, "BED");
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	const bool isOverlapping = this.getDistanceTo(caller) < this.getRadius();
	
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && bedAvailable(this) && requiresTreatment(this, carried) && isOverlapping)
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
		CBitStream params;
		params.write_netid(carried.getNetworkID());
		caller.CreateGenericButton("$worker_migrant$", Vec2f(-6, 0), this, this.getCommandID("rest"), "Rest Worker", params);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}

	this.set_bool("shop available", isOverlapping);
}

bool bedAvailable(CBlob@ this)
{
	if (this.getHealth() <= 0.0f) return false;

	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		return bed.getOccupied() is null;
	}
	return false;
}

bool requiresTreatment(CBlob@ this, CBlob@ caller)
{
	return caller.getHealth() < caller.getInitialHealth();
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attached.getShape().getConsts().collidable = false;
	attached.SetFacingLeft(true);
	attached.AddScript("WakeOnHit.as");
	
	this.SetLight(true);

	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	updateLayer(sprite, "bed", 1, true, false);
	updateLayer(sprite, "zzz", 0, true, false);
	updateLayer(sprite, "fire", 0, true, false);

	sprite.SetEmitSoundPaused(false);
	sprite.RewindEmitSound();

	CSprite@ attached_sprite = attached.getSprite();
	if (attached_sprite is null) return;

	attached_sprite.SetVisible(false);
	attached_sprite.PlaySound("GetInVehicle.ogg");

	CSpriteLayer@ head = attached_sprite.getSpriteLayer("head");
	if (head is null) return;

	Animation@ head_animation = head.getAnimation("default");
	if (head_animation is null) return;

	CSpriteLayer@ bed_head = sprite.addSpriteLayer("bed head", head.getFilename(),
		16, 16, attached.getTeamNum(), attached.getSkinNum());
	if (bed_head is null) return;

	Animation@ bed_head_animation = bed_head.addAnimation("default", 0, false);
	if (bed_head_animation is null) return;

	bed_head_animation.AddFrame(head_animation.getFrame(2));

	bed_head.SetAnimation(bed_head_animation);
	bed_head.RotateBy(80, Vec2f_zero);
	bed_head.SetOffset(Vec2f(1, 2));
	bed_head.SetFacingLeft(true);
	bed_head.SetVisible(true);
	bed_head.SetRelativeZ(2);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.getShape().getConsts().collidable = true;
	detached.AddForce(Vec2f(0, -20));
	detached.RemoveScript("WakeOnHit.as");
	
	this.SetLight(false);

	CSprite@ detached_sprite = detached.getSprite();
	if (detached_sprite !is null)
	{
		detached_sprite.SetVisible(true);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		updateLayer(sprite, "bed", 0, true, false);
		updateLayer(sprite, "zzz", 0, false, false);
		updateLayer(sprite, "fire", 0, false, false);
		updateLayer(sprite, "bed head", 0, false, true);

		sprite.SetEmitSoundPaused(true);
	}
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed is null || !isServer()) return;
	
	CBlob@[] overlapping;
	if (getGameTime() % 90 == 0 && this.getOverlapping(overlapping))
	{
		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ b = overlapping[i];
			if (!bedAvailable(this) || !requiresTreatment(this, b)) continue;

			if (!b.hasTag("migrant") || b.isAttached() || b.get_u8("strategy") == Strategy::runaway || b.get_netid("owner id") > 0) continue;

			this.server_AttachTo(b, "BED");
			break;
		}
	}

	CBlob@ patient = bed.getOccupied();
	if (patient !is null)
	{
		if (patient.getHealth() <= 0)
		{
			patient.server_DetachFrom(this);
		}
		else if (getGameTime() % heal_rate == 0)
		{
			if (requiresTreatment(this, patient))
			{
				f32 oldHealth = patient.getHealth();
				patient.server_Heal(heal_amount);
				patient.add_f32("heal amount", patient.getHealth() - oldHealth);
			}
			else
			{
				patient.server_DetachFrom(this);
			}
		}
	}
}


// SPRITE

void onInit(CSprite@ this)
{
	CSpriteLayer@ bed = this.addSpriteLayer("bed", "Quarters.png", 32, 16);
	if (bed !is null)
	{
		{
			bed.addAnimation("default", 0, false);
			int[] frames = {14, 15};
			bed.animation.AddFrames(frames);
		}
		bed.SetOffset(Vec2f(1, 4));
		bed.SetVisible(true);
	}

	CSpriteLayer@ zzz = this.addSpriteLayer("zzz", "Quarters.png", 8, 8);
	if (zzz !is null)
	{
		{
			zzz.addAnimation("default", 15, true);
			int[] frames = {96, 97, 98, 98, 99};
			zzz.animation.AddFrames(frames);
		}
		zzz.SetOffset(Vec2f(-3, -6));
		zzz.SetLighting(false);
		zzz.SetVisible(false);
	}

	CSpriteLayer@ fire = this.addSpriteLayer("fire", 8,8);
	if (fire !is null)
	{
		fire.addAnimation("default",3,true);
		int[] frames = {10,11,42,43};
		fire.animation.AddFrames(frames);
		fire.SetOffset(Vec2f(-9, 5));
		fire.SetRelativeZ(0.1f);
		fire.SetVisible(false);
	}

	this.SetEmitSound("MigrantSleep.ogg");
	this.SetEmitSoundPaused(true);
	this.SetEmitSoundVolume(0.5f);
}
