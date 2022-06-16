#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("detach");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	
	if (this.isAttachedToPoint("VEHICLE") && !this.hasAttached())
	{
		caller.CreateGenericButton(1, Vec2f(0, -4), this, this.getCommandID("detach"), "Detach");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer() && cmd == this.getCommandID("detach"))
	{
		this.server_DetachFromAll();
	}
}
