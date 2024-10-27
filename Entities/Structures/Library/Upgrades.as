//Gingerbeard @ October 7, 2024

/*
	UPGRADE IDEAS FOR THE FUTURE?
	Iron Saws        : Saws are 25% more durable
	Steel Saws       : Saws are 50% more durable
	Auto Saws        : Saws auto chop trees they are overlapping
	Swift Bearings   : Ground vehicle speed +25%
	Streamlined Hull : Boats are 25% faster
*/

//funcdef void onUpgradeHandle(CBlob@, u8);
funcdef void onUpgradeRulesHandle(CRules@, u8);

//void addOnUpgrade(CBlob@ this, onUpgradeHandle@ handle)       { this.set("onUpgrade handle", @handle); }
void addOnUpgrade(CRules@ this, onUpgradeRulesHandle@ handle) { this.set("onUpgrade handle", @handle); }

namespace Upgrade
{
	enum Index
	{
		Coinage = 0,
		CoinageII,
		CoinageIII,
		HardyWheat,
		HardyTrees,
		PlentifulWheat,
		Metallurgy,
		MetallurgyII,
		MetallurgyIII,
		MetallurgyIV,
		Refinement,
		RefinementII,        //10
		RefinementIII,
		RefinementIV,
		Extraction,
		ExtractionII,
		Milling,
		MillingII,
		MillingIII,
		Swords,
		SwordsII,
		LightArmor,          //20
		CombatPickaxes,
		LightPickaxes,
		PrecisionDrills,
		Architecture,
		Supplies,
		SuppliesII,
		SuppliesIII,
		Repeaters,
		LightBows,
		DeepQuiver,          //30
		MachineBows,
		FastBurnPowder,
		HeavyLead,
		RifledBarrels,
		Bandoliers,
		GreekFire,
		Shrapnel,
		ShrapnelII,
		HighExplosives,
		HolyWater,           //40
		BlastShields,
		FlightTuning,
		IronChassis,
		SteelChassis,
		TorsionWinch,
		SeigeCrank,
		Regeneration,
		RegenerationII,
		RegenerationIII,
		Count                //50
	}
}

u32[]@ getUpgrades()
{
	u32[]@ upgrades;
	getRules().get("upgrades", @upgrades);
	return upgrades;
}

void setUpgrade(const u8&in index)
{
	u32[]@ upgrades = getUpgrades();
	const u8 u32_index = index / 32;
	const u8 bit_index = index % 32;
	upgrades[u32_index] |= (u32(1) << bit_index);
}

bool hasUpgrade(u32[]@ upgrades, const u8&in index)
{
	const u8 u32_index = index / 32;
	const u8 bit_index = index % 32;
	return (upgrades[u32_index] & (u32(1) << bit_index)) != 0;
}

bool hasUpgrade(const u8&in index)
{
	return hasUpgrade(getUpgrades(), index);
}
