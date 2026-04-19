//Gingerbeard @ August 9, 2024

#include "EquipmentCommon.as"
#include "Zombie_Translation.as"
#include "MigrantEquipment.as"

const Vec2f[] equipment_menu_offsets =
{
	Vec2f(0, 0),
	Vec2f(0, 48),
	Vec2f(-48, 48)
};

void onInit(CBlob@ this)
{
	this.addCommandID("server_equip");
	this.addCommandID("client_equip");

	for (u8 i = 0; i < equipment.length; i++)
	{
		AddIconToken("$"+equipment[i]+"_empty$", "Equipment.png", Vec2f(24, 24), i, 0);
	}

	server_EquipHandle@ handle = @server_Equip;
	this.set("server_Equip handle", @handle);

	u16[] ids(equipment.length);
	this.set("equipment_ids", ids);
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	u16[] ids;
	if (!this.get("equipment_ids", ids)) return;

	Vec2f menu_pos = gridmenu.getUpperLeftPosition() + Vec2f(-25, 24);
	CBlob@ carried = forBlob !is null ? forBlob.getCarriedBlob() : this.getCarriedBlob();

	for (u8 i = 0; i < equipment.length; i++)
	{
		CGridMenu@ equipment_menu = CreateGridMenu(menu_pos + equipment_menu_offsets[i], this, Vec2f(1, 1), "equipment_menu");
		if (equipment_menu is null) continue;

		equipment_menu.SetCaptionEnabled(false);
		equipment_menu.deleteAfterClick = false;

		string icon = "$"+equipment[i]+"_empty$";
		string hover = "";
		
		if (carried !is null && canEquip(carried, i))
		{
			hover = Translate("Equip").replace("{ITEM}", carried.getInventoryName());
		}
		CBlob@ equipped = getBlobByNetworkID(ids[i]);
		if (equipped !is null)
		{
			icon = equipped.exists("equipment_icon") ? equipped.get_string("equipment_icon") : "$"+equipped.getName()+"$";
			hover = Translate("Unequip").replace("{ITEM}", equipped.getInventoryName());
		}

		CBitStream params;
		params.write_netid(this.getNetworkID());
		params.write_netid(carried !is null ? carried.getNetworkID() : 0);
		params.write_u8(i);
		CGridButton@ button = equipment_menu.AddButton(icon, "", "Equipment.as", "Callback_Equip", Vec2f(1, 1), params);
		if (button !is null)
		{
			button.SetHoverText(hover);
		}
	}
}

bool canEquip(CBlob@ blob, const u8&in slot)
{
	return blob.exists("equipment_slot") && blob.get_string("equipment_slot") == equipment[slot];
}

void Callback_Equip(CBitStream@ params)
{
	u16 netid;
	if (!params.saferead_netid(netid)) return;

	CBlob@ this = getBlobByNetworkID(netid);
	if (this is null) return;

	u16 item_netid;
	if (!params.saferead_netid(item_netid)) return;

	getHUD().ClearMenus();

	u8 index;
	if (!params.saferead_u8(index)) return;

	CBitStream stream;
	stream.write_u8(index);
	stream.write_netid(item_netid);
	this.SendCommand(this.getCommandID("server_equip"), stream);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_equip") && isServer())
	{
		server_Equip(this, params);
	}
	else if (cmd == this.getCommandID("client_equip") && isClient())
	{
		client_Equip(this, params);
	}
}

void server_Equip(CBlob@ this, CBitStream@ params)
{
	u16[] ids;
	this.get("equipment_ids", ids);
	u16 equipped = 0;
	u16 unequipped = 0;

	u8 index;
	if (!params.saferead_u8(index)) { error("Failed to access equipment index : "+this.getNetworkID()); return; }

	u16 item_netid;
	if (!params.saferead_netid(item_netid)) { error("Failed to access item netid : "+this.getNetworkID()); return; }

	//unequip
	CBlob@ equippedblob = getBlobByNetworkID(ids[index]);
	if (equippedblob !is null)
	{
		unequipped = ids[index];
		ids[index] = 0;
		UnequipBlob(this, equippedblob);
	}

	//equip
	CBlob@ carried = getBlobByNetworkID(item_netid);
	if (carried !is null && canEquip(carried, index))
	{
		const bool isSameEquipment = equippedblob !is null && equippedblob.getName() == carried.getName();
		if (!isSameEquipment)
		{
			equipped = carried.getNetworkID();
			ids[index] = equipped;
			EquipBlob(this, carried);
		}
	}
	this.set("equipment_ids", ids);
	
	if (!isClient()) //no need to sync on localhost
	{
		CBitStream stream;
		stream.write_netid(unequipped);
		stream.write_netid(equipped);
		SerializeEquipment(ids, stream);
		this.SendCommand(this.getCommandID("client_equip"), stream);
	}
}

void client_Equip(CBlob@ this, CBitStream@ params)
{
	u16 unequipped_netid, equipped_netid;
	if (!params.saferead_netid(unequipped_netid)) { error("Failed to access unequipped! : "+this.getNetworkID()); return; }
	if (!params.saferead_netid(equipped_netid))   { error("Failed to access equipped! : "+this.getNetworkID());   return; } 

	CBlob@ unequippedblob = getBlobByNetworkID(unequipped_netid);
	if (unequippedblob !is null)
	{
		UnequipBlob(this, unequippedblob);
	}

	CBlob@ equippedblob = getBlobByNetworkID(equipped_netid);
	if (equippedblob !is null)
	{
		EquipBlob(this, equippedblob);
	}

	if (!UnserializeEquipment(this, params)) { error("Failed to access equipment [1] : "+this.getName()+" : "+this.getNetworkID()); return; }
}

void onTick(CBlob@ this)
{
	u16[] ids;
	if (!this.get("equipment_ids", ids)) return;
	for (u8 i = 0; i < ids.length; i++)
	{
		CBlob@ equippedblob = getBlobByNetworkID(ids[i]);
		if (equippedblob is null) continue;

		// Synchronize clients in post
		if (isClient() && equippedblob.getShape().doTickScripts)
		{
			EquipBlob(this, equippedblob);
			continue;
		}

		equippedblob.setPosition(this.getPosition());

		onTickHandle@ onTickEquipped;
		if (equippedblob.get("onTickEquipped handle", @onTickEquipped))
		{
			onTickEquipped(equippedblob, this);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u16[] ids;
	if (!blob.get("equipment_ids", ids)) return;
	for (u8 i = 0; i < ids.length; i++)
	{
		CBlob@ equippedblob = getBlobByNetworkID(ids[i]);
		if (equippedblob is null) continue;

		onTickSpriteHandle@ onTickSpriteEquipped;
		if (equippedblob.get("onTickSpriteEquipped handle", @onTickSpriteEquipped))
		{
			onTickSpriteEquipped(equippedblob, this);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	u16[] ids;
	if (!this.get("equipment_ids", ids)) return damage;
	for (u8 i = 0; i < ids.length; i++)
	{
		CBlob@ equippedblob = getBlobByNetworkID(ids[i]);
		if (equippedblob is null) continue;

		onHitHandle@ onHitOwner;
		if (equippedblob.get("onHitOwner handle", @onHitOwner))
		{
			damage = onHitOwner(equippedblob, this, worldPoint, velocity, damage, hitterBlob, customData);
		}
	}
	return damage;
}

void onDie(CBlob@ this)
{
	u16[] ids;
	if (!this.get("equipment_ids", ids)) return;
	for (u8 i = 0; i < ids.length; i++)
	{
		CBlob@ equippedblob = getBlobByNetworkID(ids[i]);
		if (equippedblob is null) continue;

		UnequipBlob(this, equippedblob, false);
	}

	u16[] clear_ids(equipment.length);
	this.set("equipment_ids", clear_ids);

	EquipToNewPlayerBlob(this, ids);
}

void EquipToNewPlayerBlob(CBlob@ this, u16[]@ ids)
{
	CPlayer@ owner = this.getDamageOwnerPlayer();
	if (owner is null) return;

	CBlob@ newPlayerBlob = owner.getBlob();
	if (newPlayerBlob is null) return;

	if (newPlayerBlob is this || newPlayerBlob.hasTag("dead")) return;

	u16[]@ new_ids;
	if (!newPlayerBlob.get("equipment_ids", @new_ids)) return;

	for (u8 i = 0; i < ids.length; i++)
	{
		CBlob@ equippedblob = getBlobByNetworkID(ids[i]);
		if (equippedblob is null) continue;

		new_ids[i] = ids[i];

		EquipBlob(newPlayerBlob, equippedblob);
	}
}

///NETWORK

void SerializeEquipment(const u16[]&in ids, CBitStream@ stream)
{
	stream.write_u8(ids.length);
	for (u8 i = 0; i < ids.length; i++)
	{
		stream.write_netid(ids[i]);
	}
}

bool UnserializeEquipment(CBlob@ this, CBitStream@ stream)
{
	u8 ids_length;
	if (!stream.saferead_u8(ids_length)) return false;

	u16[] ids(ids_length);
	for (u8 i = 0; i < ids_length; i++)
	{
		if (!stream.saferead_netid(ids[i])) return false;
	}

	this.set("equipment_ids", ids);
	return true;
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	u16[] ids;
	if (this.get("equipment_ids", ids))
	{
		SerializeEquipment(ids, stream);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	if (!UnserializeEquipment(this, stream))
	{
		error("Failed to access equipment [0] : "+this.getName()+" : "+this.getNetworkID());
		return false;
	}

	return true;
}
