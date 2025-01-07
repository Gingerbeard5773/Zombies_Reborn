//common functionality for door-like objects

bool canOpenDoor(CBlob@ this, CBlob@ blob)
{
	const u8 team = this.getTeamNum();
	if (blob.getShape().getConsts().collidable && //solid
	    (blob.getRadius() > 5.0f) && //large
	    (team == 255 || team == blob.getTeamNum()) &&
	    (blob.hasTag("player") || blob.hasTag("vehicle"))) //tags that can open doors
	{
		Vec2f doorpos = this.getPosition();
		Vec2f blobpos = blob.getPosition();
	
		if (blob.hasTag("vehicle"))
		{
			if (!blob.hasTag("airship") && doorpos.y > blobpos.y + blob.getHeight()/2 + 2) return false;
	
			return canVehicleOpenDoor(this, blob);
		}
		
		if (blob.isKeyPressed(key_left)  && blobpos.x > doorpos.x && Maths::Abs(blobpos.y - doorpos.y) < 11) return true;
		if (blob.isKeyPressed(key_right) && blobpos.x < doorpos.x && Maths::Abs(blobpos.y - doorpos.y) < 11) return true;
		if (blob.isKeyPressed(key_up)    && blobpos.y > doorpos.y && Maths::Abs(blobpos.x - doorpos.x) < 11) return true;
		if (blob.isKeyPressed(key_down)  && blobpos.y < doorpos.y && Maths::Abs(blobpos.x - doorpos.x) < 11) return true;
	}
	
	return false;
}

bool canVehicleOpenDoor(CBlob@ this, CBlob@ blob)
{
	AttachmentPoint@[] aps;
	if (!blob.getAttachmentPoints(@aps)) return false;

	for (u8 i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ ap = aps[i];
		if (ap.name == "FLYER")
		{
			if (ap.isKeyPressed(key_action1))  return true;
			if (ap.isKeyPressed(key_action2))  return true;
			if (ap.isKeyPressed(key_left))     return true;
			if (ap.isKeyPressed(key_right))    return true;
		}
		else if (ap.name == "ROWER" || ap.name == "DRIVER" || ap.name == "SAIL")
		{
			if (ap.isKeyPressed(key_left))     return true;
			if (ap.isKeyPressed(key_right))    return true;
		}
	}
	
	return false;
}

bool isOpen(CBlob@ this) // used by SwingDoor, Bridge, TrapBlock
{
	return !this.getShape().getConsts().collidable;
}
