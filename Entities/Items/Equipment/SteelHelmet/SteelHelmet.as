#include "EquipmentCommon.as";
#include "RunnerTextures.as";
#include "RunnerCommon.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnHitOwner(this, @onHitOwner);
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	LoadNewHead(equipper, 170); //170 + (this.getNetworkID() % 3)
	equipper.Tag("steel helmet");
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	LoadOldHead(equipper);
	equipper.Untag("steel helmet");
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	RunnerMoveVars@ moveVars;
	if (!equipper.get("moveVars", @moveVars)) return;

	//slow down player
	moveVars.walkFactor *= 0.94f;
	//moveVars.jumpFactor *= 0.97f;
	//moveVars.canVault = false;
}

f32 onHitOwner(CBlob@ this, CBlob@ equipper, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f)
	{
		switch(customData)
		{
			case Hitters::bite:
				damage *= 0.7f;
				break;
			case Hitters::sword:
				damage *= 0.7f;
				break;
			case Hitters::spikes:
				damage *= 0.7f;
				break;
			case Hitters::bomb:
			case Hitters::explosion:
			case Hitters::keg:
			case Hitters::mine:
				damage *= 0.7f;
				break;
		}
	}

	return damage;
}
