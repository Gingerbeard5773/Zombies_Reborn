//Pull items from other storages

#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_pull_items");
}

bool isItemsInNearbyStorages(CBlob@ this)
{
	string[] pull_names;
	if (!this.get("pull_items", pull_names) || pull_names.length <= 0) return false;

	CBlob@[] nearby_storages;
	if (!getNearbyStorages(this, @nearby_storages)) return false;

	for (int s = 0; s < nearby_storages.length; s++)
	{
		CInventory@ storage_inv = nearby_storages[s].getInventory();
		for (int i = 0; i < storage_inv.getItemsCount(); i++)
		{
			CBlob@ item = storage_inv.getItem(i);
			if (pull_names.find(item.getName()) != -1) return true;
		}
	}
	return false;
}

bool getNearbyStorages(CBlob@ this, CBlob@[]@ nearby_storages)
{
	CBlob@[] storages;
	getBlobsByName("storage", @storages);
	getBlobsByName("crate", @storages);
	for (int i = 0; i < storages.length; i++)
	{
		CBlob@ storage = storages[i];
		if (storage.getDistanceTo(this) < 200.0f)
		{
			nearby_storages.push_back(storage);
		}
	}
	return nearby_storages.length > 0;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.isInventoryAccessible(caller)) return;

	if (isItemsInNearbyStorages(this) && !this.getInventory().isFull())
	{
		Vec2f offset = this.exists("pull_items_button_offset") ? this.get_Vec2f("pull_items_button_offset") : Vec2f_zero;
		CButton@ button = caller.CreateGenericButton(28, offset, this, this.getCommandID("server_pull_items"), Translate::PullItems);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_pull_items") && isServer())
	{
		string[] pull_names;
		if (!this.get("pull_items", pull_names) || pull_names.length <= 0) return;

		CBlob@[] nearby_storages;
		if (!getNearbyStorages(this, @nearby_storages)) return;
		
		CInventory@ inv = this.getInventory();

		for (int s = 0; s < nearby_storages.length; s++)
		{
			CInventory@ storage_inv = nearby_storages[s].getInventory();
			for (int i = 0; i < storage_inv.getItemsCount(); i++)
			{
				if (inv.isFull()) return;

				CBlob@ item = storage_inv.getItem(i);
				if (pull_names.find(item.getName()) == -1) continue;

				this.server_PutInInventory(item);
				i--;
			}
		}
	}
}

///NETWORK

void onSendCreateData(CBlob@ this, CBitStream@ params)
{
	string[] pull_names;
	if (!this.get("pull_items", pull_names)) return;
	
	params.write_u8(pull_names.length);
	for (u8 i = 0; i < pull_names.length; i++)
	{
		params.write_string(pull_names[i]);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ params)
{
	string[] pull_names;
	
	u8 pull_names_length;
	if (!params.saferead_u8(pull_names_length)) return false;
	for (u8 i = 0; i < pull_names_length; i++)
	{
		string pull_name;
		if (!params.saferead_string(pull_name)) return false;
		pull_names.push_back(pull_name);
	}

	if (this.exists("pull_items") || pull_names.length > 0)
	{
		this.set("pull_items", pull_names);
	}

	return true;
}
