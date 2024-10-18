#include "VehicleCommon.as";

//base vehicle code doesnt do what i want it to some times

void onInit(CBlob@ this)
{
	this.addCommandID("custom_load_ammo");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	/// LOAD AMMO
	if (cmd == this.getCommandID("custom_load_ammo") && isServer())
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;

		CBlob@[] ammos;
		string[] eligible_ammo_names;

		for (int i = 0; i < v.ammo_types.length(); ++i)
		{
			eligible_ammo_names.push_back(v.ammo_types[i].ammo_name);
		}

		// if player has item in hand, we only put that item into vehicle's inventory
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && eligible_ammo_names.find(carried.getName()) != -1)
		{
			ammos.push_back(carried);
		}
		else
		{
			CInventory@ inv = caller.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				if (eligible_ammo_names.find(item.getName()) != -1)
				{
					ammos.push_back(item);
				}
			}
		}

		for (int i = 0; i < ammos.length; i++)
		{
			if (!this.server_PutInInventory(ammos[i]))
			{
				caller.server_PutInInventory(ammos[i]);
			}
		}

		RecountAmmo(this, v);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	// find ammo in inventory
	CInventory@ inv = caller.getInventory();
	if (inv is null) return;

	for (int i = 0; i < v.ammo_types.size(); i++)
	{
		const string ammo = v.ammo_types[i].ammo_name;
		CBlob@ ammoBlob = inv.getItem(ammo);

		if (ammoBlob is null)
		{
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && carried.getName() == ammo)
			{
				@ammoBlob = carried;
			}
		}

		if (ammoBlob !is null)
		{
			Vec2f slots = this.getInventory().getInventorySlots();
			const bool canPut = slots.x * slots.y * ammoBlob.maxQuantity * ammoBlob.inventoryMaxStacks > v.ammo_types[i].ammo_stocked;
			if (!canPut) return;

			const string msg = getTranslatedString("Load {ITEM}").replace("{ITEM}", ammoBlob.getInventoryName());
			caller.CreateGenericButton("$" + ammoBlob.getName() + "$", Vec2f(), this, this.getCommandID("custom_load_ammo"), msg);
			return;
		}
	}
}
