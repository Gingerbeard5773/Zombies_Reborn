
void TryToAttachVehicle(CBlob@ blob, CBlob@ toBlob = null, const string&in ap_name = "VEHICLE")
{
	if (blob is null || blob.getAttachments() is null) return;

	AttachmentPoint@ bap1 = blob.getAttachments().getAttachmentPointByName(ap_name);
	if (bap1 is null || bap1.socket || bap1.getOccupied() !is null) return;

	CBlob@[] blobsInRadius;
	if (toBlob !is null)
		blobsInRadius.push_back(toBlob);
	else
		getMap().getBlobsInRadius(blob.getPosition(), blob.getRadius() * 1.5f + 64.0f, @blobsInRadius);

	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b.getTeamNum() == blob.getTeamNum() && b.getAttachments() !is null)
		{
			AttachmentPoint@[] aps;
			if (!b.getAttachmentPoints(@aps)) continue;

			for (uint i = 0; i < aps.length; i++)
			{
				AttachmentPoint@ ap = aps[i];
				if (ap.socket && ap.getOccupied() is null && ap.name == ap_name)
				{
					b.server_AttachTo(blob, ap);
					break;
				}
			}
		}
	}
}
