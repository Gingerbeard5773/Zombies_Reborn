#include "ArrowCommon.as"

void onInit(CBlob@ this)
{
	this.maxQuantity = 2;

	this.getCurrentScript().runFlags |= Script::remove_after_this;

	setArrowHoverRect(this);
}
