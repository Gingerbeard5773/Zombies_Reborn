// Pickup shootable items for bombers
#define SERVER_ONLY

const string[] pickup_names =
{
	"mat_arrows",
	"mat_bombs",
	"mat_waterbombs",
	"molotov"
};

//disabled tick overlapping pickup since it doesnt seem to do much
/*void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return;

	for (u16 i = 0; i < overlapping.length; i++)
	{
		pickupItem(this, overlapping[i]);
	}
}*/

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	pickupItem(this, blob);
}

void pickupItem(CBlob@ this, CBlob@ blob)
{
	if (pickup_names.find(blob.getName()) != -1 && !this.getInventory().isFull())
	{
		this.server_PutInInventory(blob);
	}
}
