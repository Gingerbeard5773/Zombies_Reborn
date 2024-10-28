//Gingerbeard @ July 24, 2024
#include "ResearchTechCommon.as";
#include "Upgrades.as";
#include "Requirements.as";
#include "Zombie_Translation.as";
#include "GetSurvivors.as";

void onInit(CRules@ this)
{
	this.addCommandID("client_synchronize_technology");
	
	addOnUpgrade(this, @onUpgrade);
	
	SetupTechTree(this);
}

void onRestart(CRules@ this)
{
	regeneration_frequency = 0;

	SetupTechTree(this);
}

void onReload(CRules@ this)
{
	SetupTechTree(this);

	onUpgrade(this, 0);
}

void SetupTechTree(CRules@ this)
{
	u32[] upgrades(Upgrade::Count / 32);
    this.set("upgrades", upgrades);

	ResearchTech@[] TechTree(Upgrade::Count);
	this.set("Technology Tree", @TechTree);

	//RESEARCH TIME REFERENCE SHEET
	//minute   : 60
	//0.5 day  : 240
	//1 day    : 480
	//1.5 day  : 720
	//2 day    : 960
	//2.5 day  : 1200
	//3 day    : 1440

	ResearchTech Coinage(Translate::Coinage, Upgrade::Coinage, Vec2f(0, 0), 30);
	AddRequirement(Coinage.requirements, "coin", "", "Coins", 150);
	Coinage.available = true; //first upgrade

	ResearchTech CoinageII(Translate::CoinageII, Upgrade::CoinageII, Vec2f(6, 5), 240);
	AddRequirement(CoinageII.requirements, "coin", "", "Coins", 1000);
	
	ResearchTech CoinageIII(Translate::CoinageIII, Upgrade::CoinageIII, Vec2f(6, 11), 1100);
	AddRequirement(CoinageIII.requirements, "coin", "", "Coins", 2500);

	ResearchTech HardyWheat(Translate::HardyWheat, Upgrade::HardyWheat, Vec2f(12, 11), 140);
	AddRequirement(HardyWheat.requirements, "coin", "", "Coins", 150);

	ResearchTech HardyTrees(Translate::HardyTrees, Upgrade::HardyTrees, Vec2f(18, 11), 140);
	AddRequirement(HardyTrees.requirements, "coin", "", "Coins", 150);

	ResearchTech PlentifulWheat(Translate::PlentifulWheat, Upgrade::PlentifulWheat, Vec2f(24, 11), 240);
	AddRequirement(PlentifulWheat.requirements, "coin", "", "Coins", 250);

	ResearchTech Metallurgy(Translate::Metallurgy, Upgrade::Metallurgy, Vec2f(0, 7), 480);
	AddRequirement(Metallurgy.requirements, "coin", "", "Coins", 500);
	AddRequirement(Metallurgy.requirements, "blob", "mat_ironingot", "Iron Ingot", 10);

	ResearchTech MetallurgyII(Translate::MetallurgyII, Upgrade::MetallurgyII, Vec2f(0, 17), 480);
	AddRequirement(MetallurgyII.requirements, "coin", "", "Coins", 750);
	AddRequirement(MetallurgyII.requirements, "blob", "mat_steelingot", "Steel Ingot", 3);

	ResearchTech MetallurgyIII(Translate::MetallurgyIII, Upgrade::MetallurgyIII, Vec2f(0, 27), 960);
	AddRequirement(MetallurgyIII.requirements, "coin", "", "Coins", 1000);
	AddRequirement(MetallurgyIII.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);

	ResearchTech MetallurgyIV(Translate::MetallurgyIV, Upgrade::MetallurgyIV, Vec2f(0, 37), 960);
	AddRequirement(MetallurgyIV.requirements, "coin", "", "Coins", 1500);
	AddRequirement(MetallurgyIV.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);
	AddRequirement(MetallurgyIV.requirements, "blob", "mat_gold", "Gold", 25);

	ResearchTech Refinement(Translate::Refinement, Upgrade::Refinement, Vec2f(6, 30), 240);
	AddRequirement(Refinement.requirements, "coin", "", "Coins", 1000);
	AddRequirement(Refinement.requirements, "blob", "mat_coal", "Coal", 100);
	AddRequirement(Refinement.requirements, "blob", "mat_gold", "Gold", 25);

	ResearchTech RefinementII(Translate::RefinementII, Upgrade::RefinementII, Vec2f(12, 30), 480);
	AddRequirement(RefinementII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementII.requirements, "blob", "mat_coal", "Coal", 100);
	AddRequirement(RefinementII.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech RefinementIII(Translate::RefinementIII, Upgrade::RefinementIII, Vec2f(18, 30), 960);
	AddRequirement(RefinementIII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementIII.requirements, "blob", "mat_coal", "Coal", 150);
	AddRequirement(RefinementIII.requirements, "blob", "mat_gold", "Gold", 75);

	ResearchTech RefinementIV(Translate::RefinementIV, Upgrade::RefinementIV, Vec2f(24, 30), 1440);
	AddRequirement(RefinementIV.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementIV.requirements, "blob", "mat_coal", "Coal", 200);
	AddRequirement(RefinementIV.requirements, "blob", "mat_gold", "Gold", 100);

	ResearchTech Extraction(Translate::Extraction, Upgrade::Extraction, Vec2f(-6, 37), 960);
	AddRequirement(Extraction.requirements, "coin", "", "Coins", 1500);
	AddRequirement(Extraction.requirements, "blob", "mat_gold", "Gold", 100);

	ResearchTech ExtractionII(Translate::ExtractionII, Upgrade::ExtractionII, Vec2f(-12, 37), 1440);
	AddRequirement(ExtractionII.requirements, "coin", "", "Coins", 3000);
	AddRequirement(ExtractionII.requirements, "blob", "mat_gold", "Gold", 150);

	ResearchTech Milling(Translate::Milling, Upgrade::Milling, Vec2f(12, 5), 240);
	AddRequirement(Milling.requirements, "coin", "", "Coins", 150);
	AddRequirement(Milling.requirements, "blob", "mat_flour", "Flour", 25);

	ResearchTech MillingII(Translate::MillingII, Upgrade::MillingII, Vec2f(18, 5), 340);
	AddRequirement(MillingII.requirements, "coin", "", "Coins", 250);
	AddRequirement(MillingII.requirements, "blob", "mat_flour", "Flour", 50);

	ResearchTech MillingIII(Translate::MillingIII, Upgrade::MillingIII, Vec2f(24, 5), 440);
	AddRequirement(MillingIII.requirements, "coin", "", "Coins", 350);
	AddRequirement(MillingIII.requirements, "blob", "mat_flour", "Flour", 100);

	ResearchTech Swords(Translate::Swords, Upgrade::Swords, Vec2f(6, 24), 240);
	AddRequirement(Swords.requirements, "coin", "", "Coins", 400);
	AddRequirement(Swords.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);

	ResearchTech SwordsII(Translate::SwordsII, Upgrade::SwordsII, Vec2f(12, 24), 380);
	AddRequirement(SwordsII.requirements, "coin", "", "Coins", 700);
	AddRequirement(SwordsII.requirements, "blob", "mat_steelingot", "Steel Ingot", 6);

	ResearchTech LightArmor(Translate::LightArmor, Upgrade::LightArmor, Vec2f(6, 37), 480);
	AddRequirement(LightArmor.requirements, "coin", "", "Coins", 400);
	AddRequirement(LightArmor.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);

	ResearchTech CombatPickaxes(Translate::CombatPickaxes, Upgrade::CombatPickaxes, Vec2f(-6, 10), 380);
	AddRequirement(CombatPickaxes.requirements, "coin", "", "Coins", 400);
	AddRequirement(CombatPickaxes.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);

	ResearchTech LightPickaxes(Translate::LightPickaxes, Upgrade::LightPickaxes, Vec2f(-6, 16), 240);
	AddRequirement(LightPickaxes.requirements, "coin", "", "Coins", 500);
	AddRequirement(LightPickaxes.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);

	ResearchTech PrecisionDrills(Translate::PrecisionDrills, Upgrade::PrecisionDrills, Vec2f(-6, 22), 240);
	AddRequirement(PrecisionDrills.requirements, "coin", "", "Coins", 600);
	AddRequirement(PrecisionDrills.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);

	ResearchTech Architecture(Translate::Architecture, Upgrade::Architecture, Vec2f(-27, 11), 240);
	AddRequirement(Architecture.requirements, "coin", "", "Coins", 300);
	AddRequirement(Architecture.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech Supplies(Translate::Supplies, Upgrade::Supplies, Vec2f(-15, 5), 240);
	AddRequirement(Supplies.requirements, "coin", "", "Coins", 250);
	AddRequirement(Supplies.requirements, "blob", "mat_stone", "Stone", 250);
	AddRequirement(Supplies.requirements, "blob", "mat_wood", "Wood", 300);

	ResearchTech SuppliesII(Translate::SuppliesII, Upgrade::SuppliesII, Vec2f(-21, 5), 340);
	AddRequirement(SuppliesII.requirements, "coin", "", "Coins", 350);
	AddRequirement(SuppliesII.requirements, "blob", "mat_stone", "Stone", 300);
	AddRequirement(SuppliesII.requirements, "blob", "mat_wood", "Wood", 450);

	ResearchTech SuppliesIII(Translate::SuppliesIII, Upgrade::SuppliesIII, Vec2f(-27, 5), 480);
	AddRequirement(SuppliesIII.requirements, "coin", "", "Coins", 400);
	AddRequirement(SuppliesIII.requirements, "blob", "mat_stone", "Stone", 400);
	AddRequirement(SuppliesIII.requirements, "blob", "mat_wood", "Wood", 800);

	ResearchTech Repeaters(Translate::Repeaters, Upgrade::Repeaters, Vec2f(-12, 17), 480);
	AddRequirement(Repeaters.requirements, "coin", "", "Coins", 400);
	AddRequirement(Repeaters.requirements, "blob", "mat_gold", "Gold", 25);

	ResearchTech LightBows(Translate::LightBows, Upgrade::LightBows, Vec2f(-12, 11), 280);
	AddRequirement(LightBows.requirements, "coin", "", "Coins", 300);
	AddRequirement(LightBows.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech DeepQuiver(Translate::DeepQuiver, Upgrade::DeepQuiver, Vec2f(-12, 23), 480);
	AddRequirement(DeepQuiver.requirements, "coin", "", "Coins", 250);
	AddRequirement(DeepQuiver.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech MachineBows(Translate::MachineBows, Upgrade::MachineBows, Vec2f(-12, 29), 960);
	AddRequirement(MachineBows.requirements, "coin", "", "Coins", 500);
	AddRequirement(MachineBows.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech FastBurnPowder(Translate::FastBurnPowder, Upgrade::FastBurnPowder, Vec2f(-18, 29), 240);
	AddRequirement(FastBurnPowder.requirements, "coin", "", "Coins", 500);

	ResearchTech HeavyLead(Translate::HeavyLead, Upgrade::HeavyLead, Vec2f(-18, 35), 480);
	AddRequirement(HeavyLead.requirements, "coin", "", "Coins", 600);
	AddRequirement(HeavyLead.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);

	ResearchTech RifledBarrels(Translate::RifledBarrels, Upgrade::RifledBarrels, Vec2f(-24, 29), 480);
	AddRequirement(RifledBarrels.requirements, "coin", "", "Coins", 400);
	AddRequirement(RifledBarrels.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);

	ResearchTech Bandoliers(Translate::Bandoliers, Upgrade::Bandoliers, Vec2f(-24, 23), 380);
	AddRequirement(Bandoliers.requirements, "coin", "", "Coins", 450);
	AddRequirement(Bandoliers.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech GreekFire(Translate::GreekFire, Upgrade::GreekFire, Vec2f(-30, 17), 480);
	AddRequirement(GreekFire.requirements, "coin", "", "Coins", 500);
	AddRequirement(GreekFire.requirements, "blob", "mat_gold", "Gold", 75);

	ResearchTech Shrapnel(Translate::Shrapnel, Upgrade::Shrapnel, Vec2f(-18, 11), 300);
	AddRequirement(Shrapnel.requirements, "coin", "", "Coins", 300);

	ResearchTech ShrapnelII(Translate::ShrapnelII, Upgrade::ShrapnelII, Vec2f(-18, 17), 480);
	AddRequirement(ShrapnelII.requirements, "coin", "", "Coins", 500);

	ResearchTech HighExplosives(Translate::HighExplosives, Upgrade::HighExplosives, Vec2f(-18, 23), 480);
	AddRequirement(HighExplosives.requirements, "coin", "", "Coins", 300);

	ResearchTech HolyWater(Translate::HolyWater, Upgrade::HolyWater, Vec2f(-24, 17), 240);
	AddRequirement(HolyWater.requirements, "coin", "", "Coins", 250);
	AddRequirement(HolyWater.requirements, "blob", "mat_gold", "Gold", 25);

	ResearchTech BlastShields(Translate::BlastShields, Upgrade::BlastShields, Vec2f(12, 37), 960);
	AddRequirement(BlastShields.requirements, "coin", "", "Coins", 1000);
	AddRequirement(BlastShields.requirements, "blob", "mat_steelingot", "Steel Ingot", 8);

	ResearchTech FlightTuning(Translate::FlightTuning, Upgrade::FlightTuning, Vec2f(18, 23), 240);
	AddRequirement(FlightTuning.requirements, "coin", "", "Coins", 250);

	ResearchTech IronChassis(Translate::IronChassis, Upgrade::IronChassis, Vec2f(18, 17), 380);
	AddRequirement(IronChassis.requirements, "coin", "", "Coins", 250);
	AddRequirement(IronChassis.requirements, "blob", "mat_ironingot", "Iron Ingot", 10);

	ResearchTech SteelChassis(Translate::SteelChassis, Upgrade::SteelChassis, Vec2f(24, 17), 480);
	AddRequirement(SteelChassis.requirements, "coin", "", "Coins", 350);
	AddRequirement(SteelChassis.requirements, "blob", "mat_steelingot", "Steel Ingot", 5);

	ResearchTech TorsionWinch(Translate::TorsionWinch, Upgrade::TorsionWinch, Vec2f(12, 17), 280);
	AddRequirement(TorsionWinch.requirements, "coin", "", "Coins", 350);
	AddRequirement(TorsionWinch.requirements, "blob", "mat_ironingot", "Iron Ingot", 2);

	ResearchTech SeigeCrank(Translate::SeigeCrank, Upgrade::SeigeCrank, Vec2f(6, 17), 240);
	AddRequirement(SeigeCrank.requirements, "coin", "", "Coins", 250);
	AddRequirement(SeigeCrank.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);

	ResearchTech Regeneration(Translate::Regeneration, Upgrade::Regeneration, Vec2f(30, 5), 480);
	AddRequirement(Regeneration.requirements, "coin", "", "Coins", 250);
	AddRequirement(Regeneration.requirements, "blob", "mat_gold", "Gold", 25);

	ResearchTech RegenerationII(Translate::RegenerationII, Upgrade::RegenerationII, Vec2f(30, 11), 560);
	AddRequirement(RegenerationII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RegenerationII.requirements, "blob", "mat_gold", "Gold", 50);

	ResearchTech RegenerationIII(Translate::RegenerationIII, Upgrade::RegenerationIII, Vec2f(30, 17), 960);
	AddRequirement(RegenerationIII.requirements, "coin", "", "Coins", 1000);
	AddRequirement(RegenerationIII.requirements, "blob", "mat_gold", "Gold", 100);
	
	// setup connections
	
	Coinage.connections.push_back(@CoinageII);
	Coinage.connections.push_back(@Supplies);
	Coinage.connections.push_back(@Metallurgy);
	CoinageII.connections.push_back(@Milling);
	CoinageII.connections.push_back(@CoinageIII);
	//CoinageIII.connections;
	//HardyWheat.connections;
	//HardyTrees.connections;
	//PlentifulWheat.connections;
	Metallurgy.connections.push_back(@MetallurgyII);
	Metallurgy.connections.push_back(@CombatPickaxes);
	MetallurgyII.connections.push_back(@MetallurgyIII);
	MetallurgyII.connections.push_back(@SeigeCrank);
	MetallurgyIII.connections.push_back(@MetallurgyIV);
	MetallurgyIII.connections.push_back(@Refinement);
	MetallurgyIII.connections.push_back(@Swords);
	MetallurgyIV.connections.push_back(@Extraction);
	MetallurgyIV.connections.push_back(@LightArmor);
	Refinement.connections.push_back(@RefinementII);
	RefinementII.connections.push_back(@RefinementIII);
	RefinementIII.connections.push_back(@RefinementIV);
	//RefinementIV.connections;
	Extraction.connections.push_back(@ExtractionII);
	//ExtractionII.connections;
	Milling.connections.push_back(@MillingII);
	Milling.connections.push_back(@HardyWheat);
	MillingII.connections.push_back(@MillingIII);
	MillingII.connections.push_back(@HardyTrees);
	MillingIII.connections.push_back(@PlentifulWheat);
	MillingIII.connections.push_back(@Regeneration);
	Swords.connections.push_back(@SwordsII);
	//SwordsII.connections;
	LightArmor.connections.push_back(@BlastShields);
	CombatPickaxes.connections.push_back(@LightPickaxes);
	LightPickaxes.connections.push_back(@PrecisionDrills);
	//PrecisionDrills.connections;
	//Architecture.connections;
	Supplies.connections.push_back(@SuppliesII);
	Supplies.connections.push_back(@Shrapnel);
	Supplies.connections.push_back(@LightBows);
	SuppliesII.connections.push_back(@SuppliesIII);
	SuppliesIII.connections.push_back(@Architecture);
	Repeaters.connections.push_back(@DeepQuiver);
	LightBows.connections.push_back(@Repeaters);
	DeepQuiver.connections.push_back(@MachineBows);
	//MachineBows.connections;
	FastBurnPowder.connections.push_back(@HeavyLead);
	FastBurnPowder.connections.push_back(@RifledBarrels);
	//HeavyLead.connections;
	//RifledBarrels.connections;
	//Bandoliers.connections;
	//GreekFire.connections;
	Shrapnel.connections.push_back(@ShrapnelII);
	ShrapnelII.connections.push_back(@HolyWater);
	ShrapnelII.connections.push_back(@HighExplosives);
	HighExplosives.connections.push_back(@FastBurnPowder);
	HighExplosives.connections.push_back(@Bandoliers);
	HolyWater.connections.push_back(@GreekFire);
	//BlastShields.connections;
	//FlightTuning.connections;
	IronChassis.connections.push_back(@SteelChassis);
	IronChassis.connections.push_back(@FlightTuning);
	//SteelChassis.connections;
	TorsionWinch.connections.push_back(@IronChassis);
	SeigeCrank.connections.push_back(@TorsionWinch);
	Regeneration.connections.push_back(@RegenerationII);
	RegenerationII.connections.push_back(@RegenerationIII);
	//RegenerationIII.connections;
	
	
	//replace the code above with the below when staging comes

	/*
	Coinage.connections =         { @CoinageII, @Supplies, @Metallurgy };
	CoinageII.connections =       { @Milling, @CoinageIII };
	CoinageIII.connections =      { };
	HardyWheat.connections =      { };
	HardyTrees.connections =      { };
	PlentifulWheat.connections =  { };
	Metallurgy.connections =      { @MetallurgyII, @CombatPickaxes };
	MetallurgyII.connections =    { @MetallurgyIII, @SeigeCrank};
	MetallurgyIII.connections =   { @MetallurgyIV, @Refinement, @Swords};
	MetallurgyIV.connections =    { @Extraction, @LightArmor };
	Refinement.connections =      { @RefinementII };
	RefinementII.connections =    { @RefinementIII };
	RefinementIII.connections =   { @RefinementIV };
	RefinementIV.connections =    { };
	Extraction.connections =      { @ExtractionII };
	ExtractionII.connections =    { };
	Milling.connections =         { @MillingII, @HardyWheat };
	MillingII.connections =       { @MillingIII, @HardyTrees };
	MillingIII.connections =      { @PlentifulWheat, @Regeneration };
	Swords.connections =          { @SwordsII };
	SwordsII.connections =        { };
	LightArmor.connections =      { @BlastShields };
	CombatPickaxes.connections =  { @LightPickaxes };
	LightPickaxes.connections =   { @PrecisionDrills };
	PrecisionDrills.connections = { };
	Architecture.connections =    { };
	Supplies.connections =        { @SuppliesII, @Shrapnel, @LightBows };
	SuppliesII.connections =      { @SuppliesIII };
	SuppliesIII.connections =     { @Architecture };
	Repeaters.connections =       { @DeepQuiver };
	LightBows.connections =       { @Repeaters };
	DeepQuiver.connections =      { @MachineBows };
	MachineBows.connections =     { };
	FastBurnPowder.connections =  { @HeavyLead, @RifledBarrels };
	HeavyLead.connections =       { };
	RifledBarrels.connections =   { };
	Bandoliers.connections =      { };
	GreekFire.connections =       { };
	Shrapnel.connections =        { @ShrapnelII };
	ShrapnelII.connections =      { @HolyWater, @HighExplosives };
	HighExplosives.connections =  { @FastBurnPowder, @Bandoliers };
	HolyWater.connections =       { @GreekFire };
	BlastShields.connections =    { };
	FlightTuning.connections =    { };
	IronChassis.connections =     { @SteelChassis, @FlightTuning };
	SteelChassis.connections =    { };
	TorsionWinch.connections =    { @IronChassis };
	SeigeCrank.connections =      { @TorsionWinch };
	Regeneration.connections =    { @RegenerationII };
	RegenerationII.connections =  { @RegenerationIII };
	RegenerationIII.connections = { };
	*/
}

void onTick(CRules@ this)
{
	if (!isServer()) return;
	
	if (regeneration_frequency <= 0) return;

	const u32 ticks_per_day = this.daycycle_speed * 1800;
	if (getGameTime() % (ticks_per_day/regeneration_frequency) != 0) return;

	CBlob@[] survivors = getSurvivors();
	for (u8 i = 0; i < survivors.length; i++)
	{
		CBlob@ survivor = survivors[i];

		const f32 initialHealth = survivor.getInitialHealth();
		const f32 heal = 0.125f;
		const f32 healthRatio = heal / (1.5f / initialHealth); //ratio the health between classes
		const f32 newHealth = Maths::Min(survivor.getHealth() + healthRatio, initialHealth);
		survivor.server_SetHealth(newHealth);
	}
}

u8 regeneration_frequency = 0;

void onUpgrade(CRules@ this, u8 upgrade)
{
	regeneration_frequency = 0;

	u32[]@ upgrades = getUpgrades();
	if (hasUpgrade(upgrades, Upgrade::Regeneration))    regeneration_frequency += 2;
	if (hasUpgrade(upgrades, Upgrade::RegenerationII))  regeneration_frequency += 2;
	if (hasUpgrade(upgrades, Upgrade::RegenerationIII)) regeneration_frequency += 4;
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod() || player.getUsername() == "MrHobo")
	{
		if (text_in == "!technology")
		{
			ResearchTech@[]@ TechTree = getTechTree();
			for (u8 i = 0; i < TechTree.length; i++)
			{
				ResearchTech@ tech = TechTree[i];
				if (tech is null) continue;
				
				tech.time_to_unlock = 1;
				tech.time = 1;

				setUpgrade(i);
			}
		}
	}
	return true;
}

/// NETWORK

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!isServer()) return;

	CBitStream stream;

	//serialize tech tree
	ResearchTech@[]@ TechTree = getTechTree();
	stream.write_u8(TechTree.length);
	for (u8 i = 0; i < TechTree.length; i++)
	{
		ResearchTech@ tech = TechTree[i];
		if (tech is null) continue;

		stream.write_u32(tech.time);
		stream.write_bool(tech.available);
		stream.write_bool(tech.paused);
	}

	//serialize upgrades
	u32[]@ upgrades = getUpgrades();
	stream.write_u8(upgrades.length);
	for (u8 i = 0; i < upgrades.length; i++)
	{
		stream.write_u32(upgrades[i]);
	}

	this.SendCommand(this.getCommandID("client_synchronize_technology"), stream, player);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_synchronize_technology") && isClient())
	{
		//unserialize tech tree
		u8 tech_tree_length;
		if (!params.saferead_u8(tech_tree_length)) return;

		ResearchTech@[]@ TechTree = getTechTree();
		const u8 client_tech_tree_length = TechTree.length;
		if (tech_tree_length != client_tech_tree_length)
		{
			error("Tech tree size desynchronized! SERVER ["+tech_tree_length+"], CLIENT["+client_tech_tree_length+"]");
			return;
		}

		for (u8 i = 0; i < tech_tree_length; i++)
		{
			ResearchTech@ tech = TechTree[i];
			if (tech is null) continue;

			if (!params.saferead_u32(tech.time))       return;
			if (!params.saferead_bool(tech.available)) return;
			if (!params.saferead_bool(tech.paused))    return;
		}

		//unserialize upgrades
		u8 upgrades_length;
		if (!params.saferead_u8(upgrades_length)) return;

		u32[] upgrades(upgrades_length);
		for (u8 i = 0; i < upgrades_length; i++)
		{
			if (!params.saferead_u32(upgrades[i])) return;
		}
		
		this.set("upgrades", upgrades); 
	}
}
