#include "VehicleCommon.as"

// Tank logic 

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
				  30.0f, // move speed
				  0.31f,  // turn speed
				  Vec2f(0.0f, 0.0f), // jump out velocity
				  false  // inventory access
				 );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupGroundSound(this, v, "WoodenWheelsRolling", // movement sound
							  1.0f, // movement sound volume modifier   0.0f = no manipulation
							  1.0f // movement sound pitch modifier     0.0f = no manipulation
							);
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 1, Vec2f(-22.0f,4.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(-15.0f,10.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(-5.0f,10.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(5.0f,10.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(15.0f,10.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 1, Vec2f(22.0f,4.0f));
	
	this.getSprite().SetZ(-50.0f);
	this.getShape().SetOffset(Vec2f(0,6));

	this.getShape().SetCenterOfMassOffset(Vec2f(0, 8));
	
	this.set_f32("map dmg modifier", 0.0f);
	
	this.Tag("invincible attachments");

	{
		Vec2f[] shape = { Vec2f(2,  8),
						  Vec2f(4, -6),
						  Vec2f(22, -6),
						  Vec2f(26,  8) };
		this.getShape().AddShape(shape);
	}

	//set custom minimap icon
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/MiniIcons.png", 11, Vec2f(16, 16));
	this.SetMinimapRenderAlways(true);
}

void onTick(CBlob@ this)
{	
	const int time = this.getTickSinceCreated();
	if (this.hasAttached() || time < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		Vehicle_StandardControls(this, v);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}
