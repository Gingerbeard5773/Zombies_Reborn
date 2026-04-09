#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "RunnerCommon.as"
#include "Hitters.as"
#include "Zombie_TechnologyCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_AchievementsCommon.as"
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

	AddIconToken("$steelarmor$", "SteelArmor.png", Vec2f(16, 16), 1, 0);

	this.setInventoryName(name(Translate::SteelArmor));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	equipper.Tag("steel armor");

	if (equipper.hasTag("steel helmet"))
	{
		CPlayer@ player = equipper.getPlayer();
		if (player !is null && player.isMyPlayer())
		{
			Achievement::client_Unlock(Achievement::IronMan);
		}
	}

	LoadArmor(this, equipper, "Steel");
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.Untag("steel armor");

	equipper.getShape().getConsts().isFlammable = true;

	UnloadArmor(this, equipper);
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	RunnerMoveVars@ moveVars;
	if (!equipper.get("moveVars", @moveVars)) return;

	Technology@[]@ TechTree = getTechTree();

	//full set gives us fire resistance if we have thermal armor tech
	if (equipper.hasTag("steel helmet") && hasTech(TechTree, Tech::ThermalArmor))
	{
		CShape@ shape = equipper.getShape();
		shape.getVars().infire = false;
		shape.getConsts().isFlammable = false;
	}

	//slow down player
	if (hasTech(TechTree, Tech::LightArmor))
	{
		moveVars.walkFactor *= 0.90f;
		moveVars.jumpFactor *= 0.95f;
		return;
	}

	moveVars.walkFactor *= 0.8f;
	moveVars.jumpFactor *= 0.9f;
}

f32 onHitOwner(CBlob@ this, CBlob@ equipper, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (equipper.hasTag("steel helmet"))
	{
		//full set gives us resistance against shit enemies
		if (hitterBlob.getName() == "skeleton" && damage > 0.0f)
		{
			ParticleMetalHit(worldPoint, damage, velocity);
			return 0.0f;
		}

		if ((customData == Hitters::fire || customData == Hitters::burn) && !equipper.getShape().getConsts().isFlammable)
		{
			this.Untag("burning");
			this.set_s16("burn timer", 0);
			this.set_s16("burn counter", 0);
			return 0.0f;
		}
	}

	if (damage <= 0.0f) return 0.0f;

	switch(customData)
	{
		case Hitters::bite:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.4f;
			break;
		case Hitters::sword:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.5f;
			break;
		case Hitters::spikes:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.5f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
			ParticleMetalHit(worldPoint, damage, velocity);
			damage *= 0.25f;
			break;
	}

	return damage;
}
