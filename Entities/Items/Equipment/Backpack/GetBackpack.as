
CBlob@ getBackpack(CBlob@ holder)
{
	u16[] ids;
	if (!holder.get("equipment_ids", ids) || ids.length < 3) return null;

	CBlob@ torso = getBlobByNetworkID(ids[2]);
	if (torso !is null && torso.getName() == "backpack")
	{
		return torso;
	}

	return null;
}
