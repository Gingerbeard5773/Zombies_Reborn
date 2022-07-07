// Zombie Fortress targeting for undeads on the ground

#define SERVER_ONLY;

void onInit(CRules@ this)
{
	u16[] netids;
	this.set("target netids", netids);
}

void onRestart(CRules@ this)
{
	this.clear("target netids");
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (!canTarget(blob)) return;
	
	this.push("target netids", blob.getNetworkID());
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (!canTarget(blob)) return;
	
	u16[] netids;
	if (!this.get("target netids", netids)) return;
	
	const int index = netids.find(blob.getNetworkID());
	if (index > -1)
	{
		this.removeAt("target netids", index);
	}
}

const bool canTarget(CBlob@ blob)
{
	return ((blob.hasTag("player") || (blob.hasTag("building") && !blob.hasTag("travel tunnel")) || blob.hasTag("vehicle")) && !blob.hasTag("undead"));
}
