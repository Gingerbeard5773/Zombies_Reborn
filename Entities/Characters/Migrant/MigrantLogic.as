#include "DecayCommon.as";
#include "HallCommon.as"
#include "KnockedCommon.as";

const string pickable_tag = "pickable";

void onInit(CBlob@ this)
{
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore_arrow");
	
	SetMigrant(this, true);

	this.getCurrentScript().tickFrequency = 150; // opt
}

void onTick(CBlob@ this)
{
	DoKnockedUpdate(this);

	if (this.hasTag("dead")) return;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return ((this.getTeamNum() == byBlob.getTeamNum() && this.getDistanceTo(byBlob) < 16.0f) || this.hasTag("dead"));
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (attached.hasTag("player"))
	{
		this.set_u8("strategy", Strategy::idle);
		ResetWorker(this);
	}
		
	if (!this.hasTag("dead"))
	{
		attachedPoint.offsetZ = -10.0f;
		this.getSprite().SetRelativeZ(-10.0f);
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.hasTag("dead"))
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		ap.offset = Vec2f(-4, 0);
		ap.offsetZ = 10.0f;
		//this.getSprite().SetRelativeZ(15.0f);
	}
}
