#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "Hitters.as"
#include "Zombie_Translation.as"
#include "ParticleMetalHit.as"

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnHitOwner(this, @onHitOwner);

	const u8 helmet_variations = 3;
	for (u8 i = 0; i < helmet_variations; i++)
	{
		AddIconToken("$goldenhelmet_"+i+"$", "GoldenHelmet.png", Vec2f(16, 16), i, 0);
	}

	this.inventoryIconFrame = this.getNetworkID() % helmet_variations;
	this.getSprite().SetFrame(this.inventoryIconFrame);
	this.set_string("equipment_icon", "$goldenhelmet_"+this.inventoryIconFrame+"$");

	this.setInventoryName(name(Translate::GoldenHelmet));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	equipper.Tag("steel helmet");
	equipper.Tag("golden helmet");

	LoadNewHead(equipper, 173 + this.inventoryIconFrame);
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	LoadOldHead(equipper);
	equipper.Untag("steel helmet");
	equipper.Untag("golden helmet");
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	//gold armor reduces stun
	if (!equipper.hasTag("sleeper"))
	{
		u8 knocked = equipper.get_u8("knocked");
		if (knocked > 1 && knocked % 3 == 0)
		{
			knocked--;
			equipper.set_u8("knocked", knocked);
		}
	}
}

f32 onHitOwner(CBlob@ this, CBlob@ equipper, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage <= 0.0f) return 0.0f;

	//give immunity to skeletons
	if (hitterBlob.getName() == "skeleton")
	{
		ParticleMetalHit(worldPoint, damage, velocity);
		return 0.0f;
	}

	switch(customData)
	{
		case Hitters::bite:
			damage *= 0.6f;
			break;
		case Hitters::sword:
			damage *= 0.6f;
			break;
		case Hitters::spikes:
			damage *= 0.5f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
			damage *= 0.6f;
			break;
	}

	return damage;
}
