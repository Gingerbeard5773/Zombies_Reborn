#include "ShieldCommon.as";
#include "ParticleSparks.as";

const int COINS_ON_DEATH = 25;
const int GRAB_COOLDOWN = 30;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32("brain_target_rad", 512.0f);
	this.set_u32("greg_next_grab", 0);
	
	this.getSprite().SetEmitSound("Wings.ogg");
	this.getSprite().SetEmitSoundPaused(false);
	
	this.getSprite().PlayRandomSound("/GregCry");
	this.getShape().SetRotationsAllowed(false);
	
	this.getBrain().server_SetActive(true);
	
	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (isServer() && blob !is null && blob is this.getBrain().getTarget() && this.get_u32("greg_next_grab") < getGameTime())
	{
		//we use server_hit for synchronization purposes (its a hack)
		//this triggers onHitBlob
		this.server_Hit(blob, point1, blob.getPosition() - this.getPosition(), 0.0f, 0, true);
		this.set_u32("greg_next_grab", getGameTime() + GRAB_COOLDOWN);
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	Sound::Play("SkeletonAttack.ogg", this.getPosition());
	if (!blockAttack(hitBlob, velocity, 0.0f)) //knights can shield against the grab
	{
		if (hitBlob is this.getBrain().getTarget()) //another check to stop unusual grabs
			this.server_AttachTo(hitBlob, "PICKUP");
	}
	else
	{
		if (isClient())
		{
			Sound::Play("ShieldHit.ogg", worldPoint);
			sparks(worldPoint, -velocity.Angle(), velocity.Length()*0.05f);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}
	return damage;
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("/GregRoar");
}
