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

	if (!blob.canBePickedUp(this)) return;

	const string name = blob.getName();

	// crossbow is special due to using multiple ammo types
	if (this.hasBlob("crossbow", 1) && arrowTypeNames.find(name) != -1)
	{
		this.server_PutInInventory(blob);
		return;
	}

	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null)
	{
		GunInfo@ gun;
		if (carried.get("gunInfo", @gun) && gun.ammo_name == name)
		{
			this.server_PutInInventory(blob);
			return;
		}
	}

	CInventory@ inv = this.getInventory();
	const int items_count = inv.getItemsCount();
	for (int i = 0; i < items_count; i++)
	{
		CBlob@ item = inv.getItem(i);
		GunInfo@ gun;
		if (item.get("gunInfo", @gun) && gun.ammo_name == name)
		{
			this.server_PutInInventory(blob);
			return;
		}
	}
}
