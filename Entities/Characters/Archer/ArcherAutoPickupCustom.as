#define SERVER_ONLY

#include "ArcherCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().vellen > 1.0f) return;

	if (arrowTypeNames.find(blob.getName()) == -1) return;

	this.server_PutInInventory(blob);
}
