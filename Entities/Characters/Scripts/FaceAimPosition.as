//set facing direction to aiming direction

void onInit(CMovement@ this)
{
	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	//this.getCurrentScript().tickFrequency = 3;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;

	const bool facing = (blob.getAimPos().x <= blob.getPosition().x);
	blob.SetFacingLeft(facing);

	// face for all attachments

	if (blob.hasAttached())
	{
		SetAttachedFacing(blob, facing);
	}
}

void SetAttachedFacing(CBlob@ blob, const bool&in facing)
{
	AttachmentPoint@[] aps;
	if (!blob.getAttachmentPoints(@aps)) return;

	for (uint i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ ap = aps[i];
		if (!ap.socket) continue;

		CBlob@ occupied = ap.getOccupied();
		if (occupied !is null && !occupied.hasTag("ignore parent facing"))
		{
			occupied.SetFacingLeft(facing);
		}
	}
}
