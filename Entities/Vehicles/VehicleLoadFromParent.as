
//auto grab ammunition from carrier vehicle
void onInventoryQuantityChange(CBlob@ this, CBlob@ blob, int oldQuantity)
{
	if (!isServer()) return;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PASSENGER");
	if (ap is null) return;

	CBlob@ vehicle = ap.getOccupied();
	if (vehicle is null) return;

	CInventory@ inv = vehicle.getInventory();
	if (inv is null) return;

	string[] autograb_blobs;
	if (!this.get("autograb blobs", autograb_blobs)) return;

	const u16 itemsCount = inv.getItemsCount();
	for (u16 i = 0; i < itemsCount; i++)
	{
		CBlob@ b = inv.getItem(i);
		if (autograb_blobs.find(b.getName()) != -1 && !this.getInventory().isFull())
		{
			this.server_PutInInventory(b);
			break;
		}
	}
}
