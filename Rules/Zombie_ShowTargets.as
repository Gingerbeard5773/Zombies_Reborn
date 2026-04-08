//Render every zombie's destination when in debug mode

#define CLIENT_ONLY;

bool showtargets = false; 

void onRender(CRules@ this)
{
	if (g_debug == 0 && !showtargets) return;

	CBlob@[] blobs;
	getBlobsByTag("migrant", @blobs);
	getBlobsByTag("undead", @blobs);

	const u16 blobsLength = blobs.length;
	for (u16 i = 0; i < blobsLength; ++i)
	{
		// draw a green line to the aim pos
		CBlob@ blob = blobs[i];
		GUI::DrawArrow2D(blob.getScreenPos(), getDriver().getScreenPosFromWorldPos(blob.getAimPos()), SColor(155, 0, 255, 0));
	}
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer())
	{
		string[]@ tokens = textIn.split(" ");
		if (tokens[0] == "!showtargets")
		{
			showtargets = !showtargets;
		}
	}
	
	return true;
}
