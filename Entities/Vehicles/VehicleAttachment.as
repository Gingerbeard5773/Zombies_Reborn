// requires VEHICLE attachment point

void onInit(CBlob@ this)
{
	this.addCommandID("detach vehicle");
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_hasattached;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() != this.getTeamNum()) return;

	AttachmentPoint@[] aps;
	if (!this.getAttachmentPoints(@aps)) return;

	for (u8 i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ ap = aps[i];
		if (ap.socket && (ap.name == "VEHICLE" || ap.name == "PASSENGER"))
		{
			CBlob@ occBlob = ap.getOccupied();
			if (occBlob !is null && occBlob.hasTag("vehicle")) //detach button
			{
				CBitStream params;
				params.write_netid(occBlob.getNetworkID());
				caller.CreateGenericButton(1, ap.offset, this, this.getCommandID("detach vehicle"), "Detach " + occBlob.getInventoryName(), params);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer() && cmd == this.getCommandID("detach vehicle"))
	{
		CBlob@ vehicle = getBlobByNetworkID(params.read_netid());
		if (vehicle !is null)
		{
			vehicle.server_DetachFrom(this);
		}
	}
}