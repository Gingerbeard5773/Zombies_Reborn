//Give players parachutes when they spawn

void onInit(CRules@ this)
{
	this.addCommandID("client_give_parachute");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_give_parachute") && isClient())
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (blob !is null)
		{
			blob.AddScript("ParachuteEffect.as");
		}
	}
}
