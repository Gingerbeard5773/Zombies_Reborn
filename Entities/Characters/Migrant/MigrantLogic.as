#include "MigrantCommon.as";
#include "KnockedCommon.as";
#include "AssignWorkerCommon.as";

void onInit(CBlob@ this)
{
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore_arrow");
	this.Tag("migrant");
	
	this.getBrain().server_SetActive(true);

	this.getCurrentScript().tickFrequency = 150; // opt
}

void onTick(CBlob@ this)
{
	DoKnockedUpdate(this);
	
	if (this.hasTag("dead"))
	{
		UpdateAssigned(this);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (this.exists("assigned netid") && this.get_netid("assigned netid") > 0) return false;

	return ((this.getTeamNum() == byBlob.getTeamNum() && this.getDistanceTo(byBlob) < 16.0f) || this.hasTag("dead"));
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (attached.hasTag("player"))
	{
		this.set_u8("strategy", Strategy::idle);
	}

	if (!this.hasTag("dead"))
	{
		this.getSprite().SetRelativeZ(-10.0f);
	}
	else
	{
		attachedPoint.offset = Vec2f(-4, 0);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!isClient()) return;

	if (blob is null || this.hasTag("dead")) return;

	if (!blob.hasTag("player") || blob.hasTag("migrant") || blob.hasTag("dead")) return;

	if (blob.getTeamNum() == this.getTeamNum() && XORRandom(10) == 0)
	{
		this.getSprite().PlaySound("/" + getTranslatedString("MigrantSayFriend"));
	}
}

void UpdateAssigned(CBlob@ this)
{
	if (!this.exists("assigned netid")) return;

	CBlob@ assigned = getBlobByNetworkID(this.get_netid("assigned netid"));
	if (assigned is null) return;

	UnassignWorker(assigned, this.getNetworkID());
}

void onDie(CBlob@ this)
{
	UpdateAssigned(this);
}
