#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.maxQuantity = 8;

	this.setInventoryName(name(Translate::IronIngot));
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
