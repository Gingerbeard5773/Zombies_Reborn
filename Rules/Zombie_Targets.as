// Zombie Fortress targeting for undeads on the ground

#define SERVER_ONLY;

#include "UndeadTeam.as"

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	u16[] netids;
	u16 undead_count = 0;

	CBlob@[] blobs;
	getBlobs(@blobs);

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob.hasTag("undead"))
		{
			undead_count++;
		}
		else if (canTarget(blob) && !isUndeadTeam(blob))
		{
			netids.push_back(blob.getNetworkID());
		}
	}

	this.set_u16("undead count", undead_count);
	this.Sync("undead count", true);

	this.set("target netids", netids);
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.add_u16("undead count", 1);
		this.Sync("undead count", true);
	}
	else if (canTarget(blob) && !isUndeadTeam(blob))
	{
		//add new target
		this.push("target netids", blob.getNetworkID());
	}

	//developer crash/bug searching, may remove this later
	if (blob.getNetworkID() == 65529)
	{
		error("[dev] Server reached blob netids maximum! Looping back to 0");
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.sub_u16("undead count", 1);
		this.Sync("undead count", true);
	}
	else if (canTarget(blob))
	{
		//remove this as target
		u16[]@ netids;
		if (!this.get("target netids", @netids)) return;
		
		const int index = netids.find(blob.getNetworkID());
		if (index > -1)
		{
			netids.erase(index);
		}
	}
}

bool canTarget(CBlob@ blob)
{
	return blob.hasTag("player");
}

///

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	SetSurvivorPlayerCount(this);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	SetSurvivorPlayerCount(this);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	SetSurvivorPlayerCount(this);
}

void SetSurvivorPlayerCount(CRules@ this)
{
	u8 count = 0;
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player !is null && player.getTeamNum() == 0)
			count++;
	}
	this.set_u8("survivor player count", count);
	this.Sync("survivor player count", true);
}
