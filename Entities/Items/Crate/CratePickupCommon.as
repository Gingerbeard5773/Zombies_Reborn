// For crate autopickups

bool crateTake(CBlob@ this, CBlob@ blob)
{
	if (this.exists("packed")) return false;

	const bool isFood = blob.exists("eat sound") && !blob.getShape().isStatic();
	if (blob.hasTag("material") || isFood)
	{
		return this.server_PutInInventory(blob);
	}
	return false;
}