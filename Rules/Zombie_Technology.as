//Gingerbeard @ July 24, 2024
#include "Requirements.as";
#include "Zombie_TechnologyCommon.as";
#include "Zombie_Translation.as";
#include "GetSurvivors.as";

void onInit(CRules@ this)
{
	this.addCommandID("client_synchronize_technology");
	
	addOnTechnology(this, @onTechnology);
	
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

	onTechnology(this, 0);
}

void SetupTechTree(CRules@ this)
{
	Technology@[] TechTree(Tech::Count);
	this.set("Tech Tree", @TechTree);

	//RESEARCH TIME REFERENCE SHEET
	//minute   : 60
	//0.5 day  : 240
	//1 day    : 480
	//1.5 day  : 720
	//2 day    : 960
	//2.5 day  : 1200
	//3 day    : 1440

	Technology Coinage(Translate::Coinage, Tech::Coinage, Vec2f(0, 0), 30);
	AddRequirement(Coinage.requirements, "coin", "", "Coins", 150);
	Coinage.available = true; //first Technology

	Technology CoinageII(Translate::CoinageII, Tech::CoinageII, Vec2f(6, 5), 240);
	AddRequirement(CoinageII.requirements, "coin", "", "Coins", 1000);
	
	Technology CoinageIII(Translate::CoinageIII, Tech::CoinageIII, Vec2f(6, 11), 1100);
	AddRequirement(CoinageIII.requirements, "coin", "", "Coins", 2500);

	Technology HardyWheat(Translate::HardyWheat, Tech::HardyWheat, Vec2f(12, 11), 140);
	AddRequirement(HardyWheat.requirements, "coin", "", "Coins", 150);

	Technology HardyTrees(Translate::HardyTrees, Tech::HardyTrees, Vec2f(18, 11), 140);
	AddRequirement(HardyTrees.requirements, "coin", "", "Coins", 150);

	Technology PlentifulWheat(Translate::PlentifulWheat, Tech::PlentifulWheat, Vec2f(24, 11), 240);
	AddRequirement(PlentifulWheat.requirements, "coin", "", "Coins", 250);

	Technology Metallurgy(Translate::Metallurgy, Tech::Metallurgy, Vec2f(0, 7), 240);
	AddRequirement(Metallurgy.requirements, "coin", "", "Coins", 500);
	AddRequirement(Metallurgy.requirements, "blob", "mat_ironingot", "Iron Ingot", 10);

	Technology MetallurgyII(Translate::MetallurgyII, Tech::MetallurgyII, Vec2f(0, 17), 380);
	AddRequirement(MetallurgyII.requirements, "coin", "", "Coins", 750);
	AddRequirement(MetallurgyII.requirements, "blob", "mat_steelingot", "Steel Ingot", 3);

	Technology MetallurgyIII(Translate::MetallurgyIII, Tech::MetallurgyIII, Vec2f(0, 27), 760);
	AddRequirement(MetallurgyIII.requirements, "coin", "", "Coins", 1000);
	AddRequirement(MetallurgyIII.requirements, "blob", "mat_steelingot", "Steel Ingot", 3);

	Technology MetallurgyIV(Translate::MetallurgyIV, Tech::MetallurgyIV, Vec2f(0, 37), 860);
	AddRequirement(MetallurgyIV.requirements, "coin", "", "Coins", 1500);
	AddRequirement(MetallurgyIV.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);
	AddRequirement(MetallurgyIV.requirements, "blob", "mat_gold", "Gold", 25);

	Technology Refinement(Translate::Refinement, Tech::Refinement, Vec2f(6, 30), 240);
	AddRequirement(Refinement.requirements, "coin", "", "Coins", 1000);
	AddRequirement(Refinement.requirements, "blob", "mat_coal", "Coal", 100);
	AddRequirement(Refinement.requirements, "blob", "mat_gold", "Gold", 25);

	Technology RefinementII(Translate::RefinementII, Tech::RefinementII, Vec2f(12, 30), 380);
	AddRequirement(RefinementII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementII.requirements, "blob", "mat_coal", "Coal", 100);
	AddRequirement(RefinementII.requirements, "blob", "mat_gold", "Gold", 50);

	Technology RefinementIII(Translate::RefinementIII, Tech::RefinementIII, Vec2f(18, 30), 760);
	AddRequirement(RefinementIII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementIII.requirements, "blob", "mat_coal", "Coal", 150);
	AddRequirement(RefinementIII.requirements, "blob", "mat_gold", "Gold", 75);

	Technology RefinementIV(Translate::RefinementIV, Tech::RefinementIV, Vec2f(24, 30), 900);
	AddRequirement(RefinementIV.requirements, "coin", "", "Coins", 750);
	AddRequirement(RefinementIV.requirements, "blob", "mat_coal", "Coal", 200);
	AddRequirement(RefinementIV.requirements, "blob", "mat_gold", "Gold", 100);

	Technology Extraction(Translate::Extraction, Tech::Extraction, Vec2f(-6, 37), 760);
	AddRequirement(Extraction.requirements, "coin", "", "Coins", 1000);
	AddRequirement(Extraction.requirements, "blob", "mat_gold", "Gold", 100);

	Technology ExtractionII(Translate::ExtractionII, Tech::ExtractionII, Vec2f(-12, 37), 1000);
	AddRequirement(ExtractionII.requirements, "coin", "", "Coins", 1500);
	AddRequirement(ExtractionII.requirements, "blob", "mat_gold", "Gold", 150);

	Technology Milling(Translate::Milling, Tech::Milling, Vec2f(12, 5), 240);
	AddRequirement(Milling.requirements, "coin", "", "Coins", 150);
	AddRequirement(Milling.requirements, "blob", "mat_flour", "Flour", 25);

	Technology MillingII(Translate::MillingII, Tech::MillingII, Vec2f(18, 5), 340);
	AddRequirement(MillingII.requirements, "coin", "", "Coins", 250);
	AddRequirement(MillingII.requirements, "blob", "mat_flour", "Flour", 50);

	Technology MillingIII(Translate::MillingIII, Tech::MillingIII, Vec2f(24, 5), 440);
	AddRequirement(MillingIII.requirements, "coin", "", "Coins", 350);
	AddRequirement(MillingIII.requirements, "blob", "mat_flour", "Flour", 100);

	Technology Swords(Translate::Swords, Tech::Swords, Vec2f(6, 24), 240);
	AddRequirement(Swords.requirements, "coin", "", "Coins", 400);
	AddRequirement(Swords.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);

	Technology SwordsII(Translate::SwordsII, Tech::SwordsII, Vec2f(12, 24), 380);
	AddRequirement(SwordsII.requirements, "coin", "", "Coins", 700);
	AddRequirement(SwordsII.requirements, "blob", "mat_steelingot", "Steel Ingot", 6);

	Technology LightArmor(Translate::LightArmor, Tech::LightArmor, Vec2f(6, 37), 480);
	AddRequirement(LightArmor.requirements, "coin", "", "Coins", 400);
	AddRequirement(LightArmor.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);

	Technology CombatPickaxes(Translate::CombatPickaxes, Tech::CombatPickaxes, Vec2f(-6, 10), 380);
	AddRequirement(CombatPickaxes.requirements, "coin", "", "Coins", 400);
	AddRequirement(CombatPickaxes.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);

	Technology LightPickaxes(Translate::LightPickaxes, Tech::LightPickaxes, Vec2f(-6, 16), 240);
	AddRequirement(LightPickaxes.requirements, "coin", "", "Coins", 500);
	AddRequirement(LightPickaxes.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);

	Technology PrecisionDrills(Translate::PrecisionDrills, Tech::PrecisionDrills, Vec2f(-6, 22), 240);
	AddRequirement(PrecisionDrills.requirements, "coin", "", "Coins", 600);
	AddRequirement(PrecisionDrills.requirements, "blob", "mat_steelingot", "Steel Ingot", 3);

	Technology Architecture(Translate::Architecture, Tech::Architecture, Vec2f(-27, 11), 240);
	AddRequirement(Architecture.requirements, "coin", "", "Coins", 300);
	AddRequirement(Architecture.requirements, "blob", "mat_gold", "Gold", 50);

	Technology Supplies(Translate::Supplies, Tech::Supplies, Vec2f(-15, 5), 240);
	AddRequirement(Supplies.requirements, "coin", "", "Coins", 250);
	AddRequirement(Supplies.requirements, "blob", "mat_stone", "Stone", 250);
	AddRequirement(Supplies.requirements, "blob", "mat_wood", "Wood", 300);

	Technology SuppliesII(Translate::SuppliesII, Tech::SuppliesII, Vec2f(-21, 5), 340);
	AddRequirement(SuppliesII.requirements, "coin", "", "Coins", 350);
	AddRequirement(SuppliesII.requirements, "blob", "mat_stone", "Stone", 300);
	AddRequirement(SuppliesII.requirements, "blob", "mat_wood", "Wood", 450);

	Technology SuppliesIII(Translate::SuppliesIII, Tech::SuppliesIII, Vec2f(-27, 5), 480);
	AddRequirement(SuppliesIII.requirements, "coin", "", "Coins", 400);
	AddRequirement(SuppliesIII.requirements, "blob", "mat_stone", "Stone", 400);
	AddRequirement(SuppliesIII.requirements, "blob", "mat_wood", "Wood", 800);

	Technology Repeaters(Translate::Repeaters, Tech::Repeaters, Vec2f(-12, 17), 280);
	AddRequirement(Repeaters.requirements, "coin", "", "Coins", 250);
	AddRequirement(Repeaters.requirements, "blob", "mat_gold", "Gold", 25);

	Technology LightBows(Translate::LightBows, Tech::LightBows, Vec2f(-12, 11), 280);
	AddRequirement(LightBows.requirements, "coin", "", "Coins", 250);
	AddRequirement(LightBows.requirements, "blob", "mat_gold", "Gold", 25);

	Technology DeepQuiver(Translate::DeepQuiver, Tech::DeepQuiver, Vec2f(-12, 23), 480);
	AddRequirement(DeepQuiver.requirements, "coin", "", "Coins", 250);
	AddRequirement(DeepQuiver.requirements, "blob", "mat_gold", "Gold", 50);

	Technology MachineBows(Translate::MachineBows, Tech::MachineBows, Vec2f(-12, 29), 960);
	AddRequirement(MachineBows.requirements, "coin", "", "Coins", 500);
	AddRequirement(MachineBows.requirements, "blob", "mat_gold", "Gold", 50);

	Technology FastBurnPowder(Translate::FastBurnPowder, Tech::FastBurnPowder, Vec2f(-18, 29), 240);
	AddRequirement(FastBurnPowder.requirements, "coin", "", "Coins", 500);

	Technology HeavyLead(Translate::HeavyLead, Tech::HeavyLead, Vec2f(-18, 35), 480);
	AddRequirement(HeavyLead.requirements, "coin", "", "Coins", 600);
	AddRequirement(HeavyLead.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);

	Technology RifledBarrels(Translate::RifledBarrels, Tech::RifledBarrels, Vec2f(-24, 29), 480);
	AddRequirement(RifledBarrels.requirements, "coin", "", "Coins", 400);
	AddRequirement(RifledBarrels.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);

	Technology Bandoliers(Translate::Bandoliers, Tech::Bandoliers, Vec2f(-24, 23), 380);
	AddRequirement(Bandoliers.requirements, "coin", "", "Coins", 450);
	AddRequirement(Bandoliers.requirements, "blob", "mat_gold", "Gold", 50);

	Technology GreekFire(Translate::GreekFire, Tech::GreekFire, Vec2f(-30, 17), 480);
	AddRequirement(GreekFire.requirements, "coin", "", "Coins", 500);
	AddRequirement(GreekFire.requirements, "blob", "mat_gold", "Gold", 50);

	Technology Shrapnel(Translate::Shrapnel, Tech::Shrapnel, Vec2f(-18, 11), 300);
	AddRequirement(Shrapnel.requirements, "coin", "", "Coins", 300);

	Technology ShrapnelII(Translate::ShrapnelII, Tech::ShrapnelII, Vec2f(-18, 17), 480);
	AddRequirement(ShrapnelII.requirements, "coin", "", "Coins", 500);

	Technology HighExplosives(Translate::HighExplosives, Tech::HighExplosives, Vec2f(-18, 23), 480);
	AddRequirement(HighExplosives.requirements, "coin", "", "Coins", 300);

	Technology HolyWater(Translate::HolyWater, Tech::HolyWater, Vec2f(-24, 17), 240);
	AddRequirement(HolyWater.requirements, "coin", "", "Coins", 250);
	AddRequirement(HolyWater.requirements, "blob", "mat_gold", "Gold", 25);

	Technology BlastShields(Translate::BlastShields, Tech::BlastShields, Vec2f(12, 37), 960);
	AddRequirement(BlastShields.requirements, "coin", "", "Coins", 1000);
	AddRequirement(BlastShields.requirements, "blob", "mat_steelingot", "Steel Ingot", 6);

	Technology FlightTuning(Translate::FlightTuning, Tech::FlightTuning, Vec2f(18, 23), 240);
	AddRequirement(FlightTuning.requirements, "coin", "", "Coins", 250);

	Technology IronChassis(Translate::IronChassis, Tech::IronChassis, Vec2f(18, 17), 380);
	AddRequirement(IronChassis.requirements, "coin", "", "Coins", 250);
	AddRequirement(IronChassis.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);

	Technology SteelChassis(Translate::SteelChassis, Tech::SteelChassis, Vec2f(24, 17), 480);
	AddRequirement(SteelChassis.requirements, "coin", "", "Coins", 350);
	AddRequirement(SteelChassis.requirements, "blob", "mat_steelingot", "Steel Ingot", 4);

	Technology TorsionWinch(Translate::TorsionWinch, Tech::TorsionWinch, Vec2f(12, 17), 280);
	AddRequirement(TorsionWinch.requirements, "coin", "", "Coins", 350);
	AddRequirement(TorsionWinch.requirements, "blob", "mat_ironingot", "Iron Ingot", 2);

	Technology SeigeCrank(Translate::SeigeCrank, Tech::SeigeCrank, Vec2f(6, 17), 240);
	AddRequirement(SeigeCrank.requirements, "coin", "", "Coins", 250);
	AddRequirement(SeigeCrank.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);

	Technology Regeneration(Translate::Regeneration, Tech::Regeneration, Vec2f(30, 5), 480);
	AddRequirement(Regeneration.requirements, "coin", "", "Coins", 250);

	Technology RegenerationII(Translate::RegenerationII, Tech::RegenerationII, Vec2f(30, 11), 560);
	AddRequirement(RegenerationII.requirements, "coin", "", "Coins", 750);
	AddRequirement(RegenerationII.requirements, "blob", "mat_gold", "Gold", 30);

	Technology RegenerationIII(Translate::RegenerationIII, Tech::RegenerationIII, Vec2f(30, 17), 960);
	AddRequirement(RegenerationIII.requirements, "coin", "", "Coins", 1000);
	AddRequirement(RegenerationIII.requirements, "blob", "mat_gold", "Gold", 50);
	
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

void onTechnology(CRules@ this, u8 tech)
{
	regeneration_frequency = 0;

	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Regeneration))    regeneration_frequency += 2;
	if (hasTech(TechTree, Tech::RegenerationII))  regeneration_frequency += 2;
	if (hasTech(TechTree, Tech::RegenerationIII)) regeneration_frequency += 4;
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod() || player.getUsername() == "MrHobo")
	{
		if (text_in == "!technology")
		{
			Technology@[]@ TechTree = getTechTree();
			for (u8 i = 0; i < TechTree.length; i++)
			{
				Technology@ tech = TechTree[i];
				if (tech is null) continue;

				tech.completed = true;
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
	Technology@[]@ TechTree = getTechTree();
	stream.write_u8(TechTree.length);
	for (u8 i = 0; i < TechTree.length; i++)
	{
		Technology@ tech = TechTree[i];
		if (tech is null) continue;

		stream.write_u32(tech.time);
		stream.write_bool(tech.available);
		stream.write_bool(tech.paused);
		stream.write_bool(tech.completed);
	}

	this.SendCommand(this.getCommandID("client_synchronize_technology"), stream, player);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_synchronize_technology") && isClient())
	{
		//unserialize tech tree
		u8 tech_tree_length;
		if (!params.saferead_u8(tech_tree_length))
		{
			error("Failed to access tech tree!");
			return;
		}

		Technology@[]@ TechTree = getTechTree();
		const u8 client_tech_tree_length = TechTree.length;
		if (tech_tree_length != client_tech_tree_length)
		{
			error("Failed to access tech tree! SERVER ["+tech_tree_length+"], CLIENT["+client_tech_tree_length+"]");
			return;
		}

		for (u8 i = 0; i < tech_tree_length; i++)
		{
			Technology@ tech = TechTree[i];
			if (tech is null) continue;

			if (!params.saferead_u32(tech.time))       { error("Tech ["+i+"] Failed [0]"); return; }
			if (!params.saferead_bool(tech.available)) { error("Tech ["+i+"] Failed [1]"); return; }
			if (!params.saferead_bool(tech.paused))    { error("Tech ["+i+"] Failed [2]"); return; }
			if (!params.saferead_bool(tech.completed)) { error("Tech ["+i+"] Failed [3]"); return; }
		}
	}
}
