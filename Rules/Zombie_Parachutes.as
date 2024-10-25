//Give players parachutes when they spawn

void onInit(CRules@ this)
{
	this.addCommandID("client_give_parachute");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_give_parachute") && isClient())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ blob = getBlobByNetworkID(netid);
		if (blob is null) return;

		blob.AddScript("ParachuteEffect.as");
	}
}
