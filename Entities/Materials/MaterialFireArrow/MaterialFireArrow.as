#include "ArrowCommon.as"

void onInit(CBlob@ this)
{
	if (isServer())
	{
		this.set_u16("decay time", 180);
	}

	this.maxQuantity = 15;

	this.getCurrentScript().runFlags |= Script::remove_after_this;

	setArrowHoverRect(this);
}
