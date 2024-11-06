#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.maxQuantity = 50;

	this.setInventoryName(Translate::Flour);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
