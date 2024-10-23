#define SERVER_ONLY

#include "ArcherCommon.as";

//todo: add in compatibility for any future guns

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

bool isPickupBlob(const string&in name)
{
	return name == "mat_musketballs" || arrowTypeNames.find(name) > -1;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	const string name = blob.getName();
	if (!isPickupBlob(name)) return;

	const string gunName = (name == "mat_musketballs") ? "musket" : "crossbow";
	if (this.hasBlob(gunName, 1))
	{
		this.server_PutInInventory(blob);
	}
}
