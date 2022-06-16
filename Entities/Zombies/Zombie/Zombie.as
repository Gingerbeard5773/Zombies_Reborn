#include "UndeadCommon.as";

const u16 ATTACK_FREQUENCY = 45;
const f32 ATTACK_DAMAGE = 0.75f;

const int COINS_ON_DEATH = 10;

void onInit(CBlob@ this)
{
	this.set_u8("attack frequency", ATTACK_FREQUENCY);
	this.set_f32("attack damage", ATTACK_DAMAGE);
	this.set_string("attack sound", "ZombieBite"+(XORRandom(2)+1));
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32(target_searchrad_property, 512.0f);

	this.getSprite().PlaySound("/ZombieSpawn");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", -3.0f);
	this.Tag("flesh");
	this.Tag("medium weight");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
	if (isClient() && XORRandom(768) == 0)
	{
		this.getSprite().PlaySound("/ZombieGroan");
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
	if (isClient() && damage > 0.0f && hitBlob.hasTag("flesh"))
	{
		Sound::Play("/ZombieHit", worldPoint);
	}
}
