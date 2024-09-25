#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("attach worker");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	
	CBitStream params;
	
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && !carried.hasTag("dead") && !this.hasAttached())
	{
		params.write_netid(carried.getNetworkID());
		CButton@ button = caller.CreateGenericButton("$worker_migrant$", Vec2f(0, 0), this, this.getCommandID("attach worker"), "Assign Worker", params);
		button.enableRadius = 30.0f;
	}
	
	CBlob@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER").getOccupied();
	if (gunner !is null && gunner.hasTag("migrant"))
	{
		params.write_netid(gunner.getNetworkID());
		CButton@ button = caller.CreateGenericButton("$worker_migrant$", Vec2f(0, 0), this, this.getCommandID("attach worker"), "Unassign Worker", params);
		button.enableRadius = 30.0f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer() && cmd == this.getCommandID("attach worker"))
	{
		CBlob@ worker = getBlobByNetworkID(params.read_netid());
		if (worker is null) return;

		if (worker.isAttachedTo(this))
		{
			this.server_DetachFrom(worker);
			return;
		}

		AttachmentPoint@ gun = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gun !is null && gun.getOccupied() is null)
		{
			worker.server_DetachFromAll();
			this.server_AttachTo(worker, @gun);
		}
	}
}
