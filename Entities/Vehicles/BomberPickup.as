// Pickup shootable items for bombers
#define SERVER_ONLY

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	pickupItem(this, blob);
}

void onTick(CBlob@ this)
{
	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return;

	for (u16 i = 0; i < overlapping.length; i++)
	{
		pickupItem(this, overlapping[i]);
	}
}

void pickupItem(CBlob@ this, CBlob@ blob)
{
    if (this is null || blob is null) return;

    // put in only if arrows & inventory is not full
    if (isArrows(blob) && this.getInventory() !is null && !this.getInventory().isFull())
    {
        this.server_PutInInventory(blob);
    }
}

bool isArrows(CBlob@ blob)
{
    if (blob is null) return false;

    string blobName = blob.getName();
    if (blobName == "mat_arrows")
    {
        return true;
    }

    return false;
}
