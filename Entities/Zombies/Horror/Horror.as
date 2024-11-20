#include "UndeadAttackCommon.as";
#include "KnockedCommon.as";
#include "Hitters.as";

const int COINS_ON_DEATH = 50;

void onInit(CBlob@ this)
{
	UndeadAttackVars attackVars;
	attackVars.frequency = 50;
	attackVars.map_factor = 20;
	attackVars.damage = 1.5f;
	attackVars.arc_length = 1.2f;
	attackVars.sound = "ZombieKnightAttack";
	this.set("attackVars", attackVars);

	this.set_f32("gib health", -3.0f);
	this.set_u16("coins on death", COINS_ON_DEATH);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.Tag("flesh");
	this.Tag("heavy weight");

	this.getSprite().SetEmitSound("HorrorChatter.ogg");
	this.getSprite().SetEmitSoundVolume(0.6f);
	this.getSprite().SetEmitSoundPaused(false);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	this.getSprite().SetEmitSoundPaused(this.hasTag("dead"));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}

	switch(customData)
	{
		case Hitters::spikes:
		case Hitters::fire:
		case Hitters::burn:
			damage *= 0.5f;
			break;
		case Hitters::flying:
		case Hitters::crush:
			damage *= 0.4f;
			break;
	}

	return damage;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isKnockable(hitBlob))
	{
		setKnocked(hitBlob, 20);
	}

	if (isClient() && damage > 0.0f && hitBlob.hasTag("flesh") && hitBlob !is this)
	{
		Sound::Play("/SwordKill2", worldPoint);
	}
}
