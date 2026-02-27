#include "EatCommon.as"

void onInit(CBlob@ this)
{
	this.set_string("eat sound", "Gurgle2.ogg");
	
	addOnEatHandle(this, @onEat);
}

void onEat(CBlob@ this, CBlob@ caller)
{
	SetDrunk(caller);
	caller.getSprite().PlaySound("gasp.ogg");
}

void SetDrunk(CBlob@ caller)
{
	if (!caller.exists("drunk") || caller.get_u16("drunk") == 0)
	{
		caller.AddScript("DrunkEffect.as");
	}
	
	caller.set_u16("drunk", Maths::Min(caller.get_u16("drunk") + 1, 250));
	caller.set_u32("next sober", getGameTime());
}
