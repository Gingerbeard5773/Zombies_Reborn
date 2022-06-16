//Render every zombie's destination when in debug mode

#define CLIENT_ONLY;

void onRender(CRules@ this)
{
	if (g_debug == 0) return;

	CBlob@[] blobs;
	if (getBlobsByTag("undead", @blobs))
	{
		const u16 blobsLength = blobs.length;
		for (u16 i = 0; i < blobsLength; ++i)
		{
			// draw a green line to the aim pos
			CBlob@ blob = blobs[i];
			GUI::DrawArrow2D(getDriver().getScreenPosFromWorldPos(blob.getPosition()), getDriver().getScreenPosFromWorldPos(blob.getAimPos()), SColor(155, 0, 255, 0));
		}
	}
}
