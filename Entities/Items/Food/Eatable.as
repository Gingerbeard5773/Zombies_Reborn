#include "EatCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("eat sound"))
	{
		this.set_string("eat sound", "/Eat.ogg");
	}

	this.addCommandID("heal command client");
	this.addCommandID("heal command server");

	this.Tag("pushedByDoor");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("heal command client") && isClient())
	{
		this.getSprite().PlaySound(this.get_string("eat sound"));
	}
	else if (cmd == this.getCommandID("heal command server") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		Heal(caller, this);
		this.SendCommand(this.getCommandID("heal command client"));
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (canHealOnCollide(this))
	{
		Heal(blob, this);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (canHealOnCollide(this))
	{
		Heal(attached, this);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!caller.isAttachedTo(this) || caller.getHealth() >= caller.getInitialHealth() || caller.hasTag("dead"))
		return;

	if (getHealingAmount(this) <= 0) return;
	
	caller.CreateGenericButton("$" + this.getName() + "$", Vec2f_zero, this, this.getCommandID("heal command server"), "Eat "+this.getInventoryName());
}
