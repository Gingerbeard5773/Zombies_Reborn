#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().vellen > 1.0f) return;

	const string blobName = blob.getName();
	if (blobName == "mat_molotovarrows" || blobName == "mat_fireworkarrows")
	{
		if (this.server_PutInInventory(blob)) return;
	}
}
