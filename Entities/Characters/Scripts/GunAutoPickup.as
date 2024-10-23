#include "ArcherCommon.as";

void Take(CBlob@ this, CBlob@ blob)
{
	const string name = blob.getName();
	if (name != "mat_musketballs" && arrowTypeNames.find(name) == -1) return;

	const string gunName = (name == "mat_musketballs") ? "musket" : "crossbow";
	if (this.hasBlob(gunName, 1))
	{
		if ((blob.getDamageOwnerPlayer() !is this.getPlayer()) || getGameTime() > blob.get_u32("autopick time"))
		{
			if (this.server_PutInInventory(blob)) return;
		}
	}
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
	if (ammoName.find(blobName) != -1)
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
