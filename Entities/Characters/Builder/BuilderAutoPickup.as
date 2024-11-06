#define SERVER_ONLY

#include "CratePickupCommon.as"
#include "GetBackpack.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 12;
	this.getCurrentScript().removeIfTag = "dead";
}

const string[] always_pickup_names =
{
	"mat_wood",
	"mat_stone",
	"mat_gold",
	"mat_iron",
	"mat_coal"
};

const string[] must_already_have_names =
{
	"mat_ironingot",
	"mat_steelingot"
};

void Take(CBlob@ this, CBlob@ blob)
{
	if (blob.getShape().vellen > 1.0f) return;

	const string blobName = blob.getName();
	if (always_pickup_names.find(blobName) != -1 || (must_already_have_names.find(blobName) != -1 && this.hasBlob(blobName, 1)))
	{
		if ((blob.getDamageOwnerPlayer() !is this.getPlayer()) || getGameTime() > blob.get_u32("autopick time"))
		{
			if (this.server_PutInInventory(blob))
				return;
			else if (server_PutInBackpack(this, blob))
				return;
		}
	}

	CBlob@ carryblob = this.getCarriedBlob();
	if (carryblob !is null && carryblob.getName() == "crate")
	{
		crateTake(carryblob, blob);
	}
}

bool server_PutInBackpack(CBlob@ this, CBlob@ blob)
{
	CBlob@ backpack = getBackpack(this);
	if (backpack is null) return false;

	return backpack.server_PutInInventory(blob);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	Take(this, blob);
}

void onTick(CBlob@ this)
{
	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return;

	for (u16 i = 0; i < overlapping.length; i++)
	{
		Take(this, overlapping[i]);
	}
}

// make ignore collision time a lot longer for auto-pickup stuff
void IgnoreCollisionLonger(CBlob@ this, CBlob@ blob)
{
	if (this.hasTag("dead")) return;

	const string blobName = blob.getName();
	if (always_pickup_names.find(blobName) != -1 || must_already_have_names.find(blobName) != -1)
	{
		blob.set_u32("autopick time", getGameTime() +  getTicksASecond() * 7);
		blob.SetDamageOwnerPlayer(this.getPlayer());
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	IgnoreCollisionLonger(this, detached);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	IgnoreCollisionLonger(this, blob);
}
