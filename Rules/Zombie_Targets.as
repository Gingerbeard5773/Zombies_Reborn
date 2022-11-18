// Zombie Fortress targeting for undeads on the ground

#define SERVER_ONLY;

void onInit(CRules@ this)
{
	this.set_u16("undead count", 0);
	
	u16[] netids;
	this.set("target netids", netids);
}

void onRestart(CRules@ this)
{
	this.set_u16("undead count", 0);
	this.clear("target netids");
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.add_u16("undead count", 1);
	}
	else if (canTarget(blob))
	{
		//add new target
		this.push("target netids", blob.getNetworkID());
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.sub_u16("undead count", 1);
	}
	else if (canTarget(blob))
	{
		//remove this as target
		u16[] netids;
		if (!this.get("target netids", netids)) return;
		
		const int index = netids.find(blob.getNetworkID());
		if (index > -1)
		{
			this.removeAt("target netids", index);
		}
	}
}

const bool canTarget(CBlob@ blob)
{
	return (blob.hasTag("player") || blob.hasTag("vehicle"));
}
