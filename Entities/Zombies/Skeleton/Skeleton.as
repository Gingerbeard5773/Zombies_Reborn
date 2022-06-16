#include "UndeadCommon.as";

const u8 ATTACK_FREQUENCY = 30; // 30 = 1 second
const f32 ATTACK_DAMAGE = 0.5f;

const int COINS_ON_DEATH = 5;

void onInit(CBlob@ this)
{
	this.set_u8("attack frequency", ATTACK_FREQUENCY);
	this.set_f32("attack damage", ATTACK_DAMAGE);
	this.set_string("attack sound", "SkeletonAttack");
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32(target_searchrad_property, 512.0f);

	this.getSprite().PlayRandomSound("/SkeletonSpawn");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", 0.0f);
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
