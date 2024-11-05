#include "ArrowCommon.as"
#include "Zombie_Translation.as"

void onInit(CBlob@ this)
{
	this.maxQuantity = 2;

	this.getCurrentScript().runFlags |= Script::remove_after_this;

	setArrowHoverRect(this);
	
	this.setInventoryName(name(Translate::MolotovArrows));
}
