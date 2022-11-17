#define SERVER_ONLY

const u8 obstruction_threshold = 40; // 30 = 1 second

void onInit(CBrain@ this)
{
	this.getBlob().set_u16("brain_obstruction_threshold", 0);
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;
	
	// know when we're stuck, and fix it
	DetectObstructions(this, blob);
}

void DetectObstructions(CBrain@ this, CBlob@ blob)
{
	u8 threshold = blob.get_u16("brain_obstruction_threshold");

	const bool up = blob.isKeyPressed(key_up);
	const bool obstructed = up && (blob.getPosition() - blob.getOldPosition()).Length() < 0.1f;
	if (obstructed)
		threshold++;
	else if (threshold > 0)
		threshold--;
		
	// check if stuck near a tile
	if (threshold >= obstruction_threshold)
	{
		CBlob@ carried = blob.getCarriedBlob(); //for gregs
		if (carried !is null)
			carried.server_DetachFrom(blob);
		
		this.SetTarget(null);
		blob.set_Vec2f("brain_destination", Vec2f_zero); //reset our destination
		
		threshold = 0;
	}
	
	blob.set_u16("brain_obstruction_threshold", threshold);
}
