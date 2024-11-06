#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.maxQuantity = 250;

	this.getCurrentScript().runFlags |= Script::remove_after_this;
	
	this.setInventoryName(name(Translate::Coal));
}
