#include "UndeadAttackCommon.as";

const int COINS_ON_DEATH = 5;

void onInit(CBlob@ this)
{
	UndeadAttackVars attackVars;
	attackVars.frequency = 30;
	attackVars.map_factor = 45;
	attackVars.damage = 0.5f;
	attackVars.sound = "SkeletonAttack";
	this.set("attackVars", attackVars);
	
	this.set_f32("gib health", 0.0f);
	this.set_u16("coins on death", COINS_ON_DEATH);

	this.getSprite().PlayRandomSound("/SkeletonSpawn");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.Tag("flesh");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (isClient() && XORRandom(768) == 0)
	{
		this.getSprite().PlaySound("/SkeletonSayDuh");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("/SkeletonHit");
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		this.getSprite().PlaySound("/SkeletonBreak1");
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isClient() && damage > 0.0f && hitBlob.hasTag("flesh"))
	{
		Sound::Play("/Kick", worldPoint);
	}
}
