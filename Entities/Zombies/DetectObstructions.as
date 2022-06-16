#define SERVER_ONLY

#include "UndeadCommon.as";

const u16 OBSTRUCTION_THRESHOLD = 60; // 30 = 1 second

void onInit(CBrain@ this)
{
	this.getBlob().set_u16(obstruction_threshold, 0);
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
	u16 threshold = blob.get_u16(obstruction_threshold);

	Vec2f mypos = blob.getPosition();

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	const bool obstructed = up && getMap().isTileSolid(mypos - Vec2f(0.0f, 1.3f * blob.getRadius()) * 1.0f);
	if (obstructed)
		threshold++;
	else if (threshold > 0)
		threshold--;
		
	
	// check if stuck near a tile
	if (threshold >= OBSTRUCTION_THRESHOLD)
	{
		this.SetTarget(null);
		blob.set_Vec2f(destination_property, Vec2f_zero); //reset our destination
		
		threshold = 0;
	}
	
	blob.set_u16(obstruction_threshold, threshold);
}
