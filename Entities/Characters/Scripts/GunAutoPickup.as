#define SERVER_ONLY

#include "ArcherCommon.as"
#include "GunCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.hasTag("no pickup")) return;

	const string name = blob.getName();

	// crossbow is special
	if (this.hasBlob("crossbow", 1) && arrowTypeNames.find(name) != -1)
	{
		this.server_PutInInventory(blob);
		return;
	}

	CBlob@[] inventory_guns;
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null && carried.hasTag("gun"))
	{
		inventory_guns.push_back(carried);
	}

	CInventory@ inv = this.getInventory();
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		if (!item.hasTag("gun")) continue;

		inventory_guns.push_back(item);
	}

	for (int i = 0; i < inventory_guns.length; i++)
	{
		CBlob@ inventory_gun = inventory_guns[i];

		GunInfo@ gun;
		if (!inventory_gun.get("gunInfo", @gun)) return;

		if (gun.ammo_name == name)
		{
			this.server_PutInInventory(blob);
			break;
		}
	}
}
