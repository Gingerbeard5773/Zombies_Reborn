#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.maxQuantity = 4;

	this.getCurrentScript().runFlags |= Script::remove_after_this;
	
	this.setInventoryName(name(Translate::MusketBalls));
}
