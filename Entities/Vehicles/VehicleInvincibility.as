//Gingerbeard @ September 1, 2024
//Give players & vehicles invincibility when they are attached to vehicles

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	const bool canApply = this.hasTag("invincible attachments") ? true : this.hasTag("invincible");
	if (canBlobBeInvincible(attached) && canApply && attachedPoint.socket)
	{
		SetInvincibility(attached, true);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.socket)
	{
		SetInvincibility(detached, false);
	}
}

bool canBlobBeInvincible(CBlob@ blob)
{
	return blob.hasTag("player") || blob.hasTag("vehicle");
}

void SetInvincibility(CBlob@ blob, const bool&in invincible)
{
	blob.set_bool("invincible", invincible);

	if (blob.hasTag("invincible attachments")) return;

	const u8 count = blob.getAttachmentPointCount();
	for (u8 i = 0; i < count; i++)
	{
		AttachmentPoint@ ap = blob.getAttachmentPoint(i);
		CBlob@ attached = ap.getOccupied();
		if (attached is null || !ap.socket) continue;
		
		if (canBlobBeInvincible(attached))
		{
			SetInvincibility(attached, invincible);
		}
	}
}
