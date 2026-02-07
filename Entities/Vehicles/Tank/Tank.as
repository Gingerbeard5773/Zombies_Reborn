#include "VehicleCommon.as"
#include "Zombie_TechnologyCommon.as"
#include "Zombie_AchievementsCommon.as"

// Tank logic 

const f32 move_speed = 35.0f;

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
				  move_speed, // move speed
				  0.31f,  // turn speed
				  Vec2f(0.0f, 0.0f), // jump out velocity
				  true  // inventory access
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
		
		if (hasTech(Tech::SwiftBearings))
		{
			v.move_speed = move_speed * 1.3f;
		}

		Vehicle_StandardControls(this, v);
	}

	/// Achievement

	if (isClient() && getGameTime() % 60 == 0)
	{
		const u16 plowed = Maths::Max(this.get_u16("undead_plowed") - 1, 0);
		this.set_u16("undead_plowed", plowed);
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	const f32 ratio = 1.0f - (this.getHealth() / this.getInitialHealth());
	this.getSprite().animation.setFrameFromRatio(ratio);
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

/// Achievement

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player is null || !player.isMyPlayer()) return;

	if (!hitBlob.hasTag("undead")) return;

	if (hitBlob.getHealth() > hitBlob.get_f32("gib health")) return;

	const u16 plowed = this.get_u16("undead_plowed") + 1;
	this.set_u16("undead_plowed", plowed);

	if (plowed == 40)
	{
		Achievement::client_Unlock(Achievement::Plow);
	}
}
