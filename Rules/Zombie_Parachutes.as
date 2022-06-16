//Give players parachutes when they spawn

void onInit(CRules@ this)
{
	this.addCommandID("give_parachute");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("give_parachute"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (blob !is null)
		{
			blob.AddScript("ParachuteEffect.as");
		}
	}
}
