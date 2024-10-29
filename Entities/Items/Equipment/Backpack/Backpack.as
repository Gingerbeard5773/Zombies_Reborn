#include "EquipmentCommon.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "torso");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);
	addOnClientJoin(this, @onClientJoin);
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	this.set_netid("equipper_id", equipper.getNetworkID());
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	this.getSprite().SetVisible(true);
	equipper.getSprite().RemoveSpriteLayer("backpack");
	
	this.set_netid("equipper_id", 0);
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	this.getSprite().SetVisible(false);
	this.setPosition(equipper.getPosition());
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ backpack = equipper_sprite.getSpriteLayer("backpack");
	if (backpack is null)
	{
		//add backpack spritelayer. done in onTick because KAG ENGINE IS FUCKING SHIT AND CANT SYNC NEW CLIENTS PROPERLY.
		@backpack = equipper_sprite.addSpriteLayer("backpack", "Backpack.png", 16, 16);
		if (backpack !is null)
		{
			backpack.SetVisible(true);
			backpack.SetRelativeZ(-2);
			backpack.SetOffset(Vec2f(4, -2));

			if (equipper_sprite.isFacingLeft())
				backpack.SetFacingLeft(true);
		}
	}
	if (backpack !is null)
	{
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, 0);
       
		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(4, 2);
		backpack.SetOffset(headoffset);
	}
}

void onClientJoin(CBlob@ this, CBlob@ equipper)
{
	OnEquip(this, equipper);
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	CBlob@ inventoryBlob = this.getInventoryBlob();
	if (inventoryBlob !is null)
	{
		inventoryBlob.server_PutInInventory(blob);
	}
	else
	{
		this.getSprite().PlaySound("/PutInInventory.ogg");
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	//can only put in inventory if we dont have items
	return this.getInventory().getItem(0) is null;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.get_netid("equipper_id") == 0;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	const u16 equipper_id = this.get_netid("equipper_id");
	if (equipper_id == 0) return true;

	return forBlob.getNetworkID() == equipper_id;
}
