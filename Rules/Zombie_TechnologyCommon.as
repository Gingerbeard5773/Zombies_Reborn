//Gingerbeard @ July 24, 2024

//Tech Tree system

/*
	TECH IDEAS FOR THE FUTURE?
	Iron Saws        : Saws are 25% more durable
	Steel Saws       : Saws are 50% more durable
	Auto Saws        : Saws auto chop trees they are overlapping
*/

//funcdef void onTechnologyHandle(CBlob@, u8);
funcdef void onTechnologyRulesHandle(CRules@, u8);

//void addOnTechnology(CBlob@ this, onTechnologyHandle@ handle)       { this.set("onTechnology handle", @handle); }
void addOnTechnology(CRules@ this, onTechnologyRulesHandle@ handle) { this.set("onTechnology handle", @handle); }

namespace Tech
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
		ThermalArmor,        //50
		ThermalHull,
		SwiftBearings,
		Chainmail,
		LightSwords,
		Production,
		ProductionII,
		Count
	}
}

shared class Technology
{
	string description; //visible name and description
	u8 index;           //Technology index and sprite frame
	Vec2f offset;       //position on the GUI
	u32 time_to_unlock; //how many seconds it will take to unlock this tech
	u32 time;           //the gametime when this tech will be unlocked
	bool available;     //true if the tech is next to be researched in the tech tree
	bool paused;        //research is paused
	bool completed;     //research is completed

	CBitStream requirements;

	Technology@[] connections;
	
	Technology(const string&in description, const u8&in index, Vec2f&in offset, const u32&in time_to_unlock)
	{
		this.description = description;
		this.index = index;
		this.offset = offset;
		this.time_to_unlock = time_to_unlock;
		this.time = 0;
		this.available = false;
		this.paused = false;
		this.completed = false;

		Technology@[]@ TechTree;
		getRules().get("Tech Tree", @TechTree);
		@TechTree[index] = @this;
	}

	bool isResearching() { return time > 0 && !completed; }
	f32 getPercent() { return f32(time) / f32(time_to_unlock); }
	
	bool opEquals(Technology@ tech)
	{
		return this is tech;
	}
}

Technology@[]@ getTechTree()
{
	Technology@[]@ TechTree;
	getRules().get("Tech Tree", @TechTree);
	return TechTree;
}

Technology@ getResearching(CBlob@ this)
{
	const int index = this.get_s32("researching");
	if (index < 0) return null;

	return getTech(index);
}

Technology@ getTech(Technology@[]@ TechTree, const u8&in index)
{
	if (index >= TechTree.length)
	{
		error("Attempted to access invalid tech tree index! INDEX: "+index);
		printTrace();
		return null;
	}

	return TechTree[index];
}

Technology@ getTech(const u8&in index)
{
	return getTech(getTechTree(), index);
}

bool hasTech(Technology@[]@ TechTree, const u8&in index)
{
	Technology@ tech = getTech(TechTree, index);
	if (tech is null) return false;
	
	return tech.completed;
}

bool hasTech(const u8&in index)
{
	return hasTech(getTechTree(), index);
}
