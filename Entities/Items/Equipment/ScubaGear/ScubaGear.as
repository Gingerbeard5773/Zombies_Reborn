#include "EquipmentCommon.as";
#include "RunnerTextures.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);

	AddIconToken("$scubagear$", "ScubaGear.png", Vec2f(16, 16), 1, 0);

	this.setInventoryName(name(Translate::ScubaGear));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	LoadNewHead(equipper, 146);

	equipper.Tag("scubagear");

	if (equipper.exists("air_count"))
	{
		equipper.set_u8("air_count", 180);
		equipper.RemoveScript("RunnerDrowning.as");
	}
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	LoadOldHead(equipper);

	equipper.Untag("scubagear");

	if (equipper.exists("air_count"))
	{
		equipper.AddScript("RunnerDrowning.as");
	}
}
