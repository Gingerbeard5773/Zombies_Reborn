#include "EquipmentCommon.as";
#include "RunnerTextures.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "ParticleSparks.as";
#include "Zombie_TechnologyCommon.as";
#include "Zombie_Translation.as";

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

	string spritename = "";
	if (equipper.getName() == "knight")        spritename = "KnightSteelArmor";
	else if (equipper.getName() == "builder")  spritename = "BuilderSteelArmor";
	else if (equipper.getName() == "archer")   spritename = "ArcherSteelArmor";

	if (!spritename.isEmpty())
		equipper.getSprite().ReloadSprite(spritename, 32, 32, equipper.getTeamNum(), equipper.getSkinNum());
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.Untag("steel armor");
	
	equipper.getShape().getConsts().isFlammable = true;

	string spritename = "";
	const bool female = this.getSexNum() == 1;
	if (equipper.getName() == "knight")        spritename = female ? "KnightFemale" : "KnightMale";
	else if (equipper.getName() == "builder")  spritename = female ? "BuilderFemale" : "BuilderMale";
	else if (equipper.getName() == "archer")   spritename = female ? "ArcherFemale" : "ArcherMale";
	
	if (!spritename.isEmpty())
		equipper.getSprite().ReloadSprite(spritename, 32, 32, equipper.getTeamNum(), equipper.getSkinNum());
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
		if (hitterBlob.getName() == "skeleton")
		{
			DoMetalHitEffects(equipper, damage, worldPoint, velocity);
			return 0.0f;
		}

		/*if ((customData == Hitters::fire || customData == Hitters::burn))
		{
			return 0.0f;
		}*/
	}

	switch(customData)
	{
		case Hitters::bite:
			DoMetalHitEffects(equipper, damage, worldPoint, velocity);
			damage *= 0.4f;
			break;
		case Hitters::sword:
			DoMetalHitEffects(equipper, damage, worldPoint, velocity);
			damage *= 0.5f;
			break;
		case Hitters::spikes:
			DoMetalHitEffects(equipper, damage, worldPoint, velocity);
			damage *= 0.5f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
			DoMetalHitEffects(equipper, damage, worldPoint, velocity);
			damage *= 0.25f;
			break;
	}

	return damage;
}

void DoMetalHitEffects(CBlob@ this, const f32&in damage, Vec2f position, Vec2f velocity)
{
	const f32 vol = Maths::Min(damage * 0.5f, 0.5f);
	this.getSprite().PlaySound("ShieldHit.ogg", 0.5f + vol, 0.85f + (XORRandom(100) / 1000.0f));
	sparks(position, velocity.Angle(), 1);
}
