#include "UndeadAttackCommon.as";
#include "KnockedCommon.as";

const int COINS_ON_DEATH = 35;

void onInit(CBlob@ this)
{
	UndeadAttackVars attackVars;
	attackVars.frequency = 60;
	attackVars.map_factor = 27;
	attackVars.damage = 1.25f;
	attackVars.arc_length = 1.0f;
	attackVars.sound = "ZombieKnightAttack";
	this.set("attackVars", attackVars);
	
	this.set_f32("gib health", -3.0f);
	this.set_u16("coins on death", COINS_ON_DEATH);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.Tag("flesh");
	this.Tag("heavy weight");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
	if (isClient() && XORRandom(1024) == 0)
	{
		this.getSprite().PlaySound("/ZombieKnightGrowl");
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

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isKnockable(hitBlob))
	{
		setKnocked(hitBlob, 10);
	}
	
	if (isClient() && damage > 0.0f && hitBlob.hasTag("flesh") && hitBlob !is this)
	{
		Sound::Play("/SwordKill2", worldPoint);
	}
}
