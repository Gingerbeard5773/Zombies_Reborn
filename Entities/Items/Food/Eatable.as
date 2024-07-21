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
	if (cmd == this.getCommandID("heal command server") && isServer())
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller !is null)
		{
			Heal(caller, this);
			this.SendCommand(this.getCommandID("heal command client"));
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null)
	{
		return;
	}

	if ((this.getName() == "heart" || this.getName() == "flowers") && isServer() && !blob.hasTag("dead"))
	{
		Heal(blob, this);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this is null || attached is null) return;

	CPlayer@ p = attached.getPlayer();
	if (p is null) return;

	this.set_u16("healer", p.getNetworkID());
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (this is null || detached is null) return;

	CPlayer@ p = detached.getPlayer();
	if (p is null) return;

	this.set_u16("healer", p.getNetworkID());
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!caller.isAttachedTo(this) || caller.getHealth() >= caller.getInitialHealth() || caller.hasTag("dead"))
		return;
		
	u8 heal_amount = getHealingAmount(this);
	if (heal_amount <= 0) return;
	
	CBitStream params;
	params.write_netid(caller.getNetworkID());
	caller.CreateGenericButton("$" + this.getName() + "$", Vec2f_zero, this, this.getCommandID("heal command server"), "Eat "+this.getInventoryName(), params);
}
