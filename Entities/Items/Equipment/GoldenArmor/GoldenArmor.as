#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "RunnerCommon.as"
#include "Hitters.as"
#include "Zombie_TechnologyCommon.as"
#include "Zombie_Translation.as"
#include "ParticleMetalHit.as"

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "torso");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnHitOwner(this, @onHitOwner);

	AddIconToken("$goldenarmor$", "GoldenArmor.png", Vec2f(16, 16), 1, 0);

	this.setInventoryName(name(Translate::GoldenArmor));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	equipper.Tag("steel armor");
	equipper.Tag("golden armor");

	LoadArmor(this, equipper, "Golden");
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.Untag("steel armor");
	equipper.Untag("golden armor");
	
	equipper.getShape().getConsts().isFlammable = true;

	UnloadArmor(this, equipper);
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	RunnerMoveVars@ moveVars;
	if (!equipper.get("moveVars", @moveVars)) return;

	//gold armor reduces stun
	if (!equipper.hasTag("sleeper"))
	{
		u8 knocked = equipper.get_u8("knocked");
		if (knocked > 1 && knocked % 2 == 0)
		{
			knocked--;
			equipper.set_u8("knocked", knocked);
		}
	}

	Technology@[]@ TechTree = getTechTree();

	//full set gives us fire resistance even if its only a steel helmet
	if (equipper.hasTag("steel helmet"))
	{
		CShape@ shape = equipper.getShape();
		shape.getVars().infire = false;
		shape.getConsts().isFlammable = false;
	}

	//slow down player
	if (hasTech(TechTree, Tech::LightArmor))
	{
		moveVars.walkFactor *= 0.92f;
		moveVars.jumpFactor *= 0.97f;
		return;
	}

	moveVars.walkFactor *= 0.82f;
	moveVars.jumpFactor *= 0.92f;
}

f32 onHitOwner(CBlob@ this, CBlob@ equipper, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((customData == Hitters::fire || customData == Hitters::burn) && !equipper.getShape().getConsts().isFlammable)
	{
		this.Untag("burning");
		this.set_s16("burn timer", 0);
		this.set_s16("burn counter", 0);
		return 0.0f;
	}

	if (damage <= 0.0f) return 0.0f;

	//give immunity to skeletons
	if (hitterBlob.getName() == "skeleton")
	{
		ParticleMetalHit(worldPoint, damage, velocity);
		return 0.0f;
	}

	//full golden set gives us immunity against basic zombie
	if (equipper.hasTag("golden helmet") && hitterBlob.getName() == "zombie")
	{
		ParticleMetalHit(worldPoint, damage, velocity);
		return 0.0f;
	}

	switch(customData)
	{
		case Hitters::bite:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.3f;
			break;
		case Hitters::sword:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.4f;
			break;
		case Hitters::spikes:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.0f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.15f;
			break;
	}

	return damage;
}
