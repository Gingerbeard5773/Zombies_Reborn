//Zombie Fortress Statistics
// Gingerbeard @ Jan 30, 2026

#include "Zombie_Translation.as"

/*
	Statistics todo
	bombs, water bombs, kegs, molotovs used
	trees felled
*/

namespace Statistics
{
	const string[] statistic_names =
	{
		"undead_killed",
		"deaths",
		"play_time",
		"wood_blocks_placed",
		"stone_blocks_placed",
		"iron_blocks_placed",
		"dirt_blocks_placed",
		"blocks_placed",
		"spikes_placed",
		"doors_placed",
		"ladders_placed",
		"platforms_placed",
		"trap_blocks_placed",
		"components_placed",
		"buildings_placed",
		"factories_setup",
		"food_eaten",
		"scrolls_used",
		"technologies_researched",
		"arrows_shot",
		"fire_arrows_shot",
		"water_arrows_shot",
		"bomb_arrows_shot",
		"molotov_arrows_shot",
		"fireworks_launched",
		"guns_fired",
		"bolts_fired",
		"cannons_fired"
	};
	
	const string[] statistic_translate =
	{
		Translate::StatUndeadKilled,
		Translate::StatDeaths,
		Translate::StatPlayTime,
		Translate::StatWoodBlocks,
		Translate::StatStoneBlocks,
		Translate::StatIronBlocks,
		Translate::StatDirtBlocks,
		Translate::StatBlocks,
		Translate::StatSpikes,
		Translate::StatDoors,
		Translate::StatLadders,
		Translate::StatPlatforms,
		Translate::StatTrapBlocks,
		Translate::StatComponents,
		Translate::StatBuildings,
		Translate::StatFactories,
		Translate::StatFood,
		Translate::StatScrolls,
		Translate::StatTechs,
		Translate::StatArrows,
		Translate::StatFireArrows,
		Translate::StatWaterArrows,
		Translate::StatBombArrows,
		Translate::StatMolotovArrows,
		Translate::StatFireworks,
		Translate::StatGuns,
		Translate::StatBolts,
		Translate::StatCannons
	};

	enum Type
	{
		Current,
		AllTime
	}

	const string filename = "Zombie_Statistics.cfg";

	ConfigFile@ openConfig()
	{
		ConfigFile cfg = ConfigFile();
		if (!cfg.loadFile("../Cache/"+filename))
		{
			warn("Creating statistics config ../Cache/"+filename);
			cfg.saveFile(filename);
		}

		return cfg;
	}

	void AddToConfig(const string&in statistic_name, const u32&in amount, ConfigFile@ cfg = openConfig())
	{
		const string statistic = cfg.exists(statistic_name) ? cfg.read_string(statistic_name) : "0 0";
		string[]@ values = statistic.split(" ");

		const u32 current_value = parseInt(values[Current]) + amount;
		const u32 alltime_value = parseInt(values[AllTime]) + amount;

		cfg.add_string(statistic_name, current_value + " " + alltime_value);

		cfg.saveFile(filename);
	}

	void Add(const string&in statistic_name, const u32&in amount, ConfigFile@ cfg = openConfig())
	{
		dictionary@ statistics_set;
		if (!getRules().get("statistics_set", @statistics_set)) return;

		u32 value = 0;
		statistics_set.get(statistic_name, value);
		statistics_set.set(statistic_name, value + amount);
	}

	u32 Get(const string&in statistic_name, const Type&in statistic_type, ConfigFile@ cfg = openConfig())
	{
		const string statistic = cfg.exists(statistic_name) ? cfg.read_string(statistic_name) : "0 0";
		string[]@ values = statistic.split(" ");

		return parseInt(values[statistic_type]);
	}

	void server_Add(const string&in statistic_name, const u32&in amount, CPlayer@ player)
	{
		CBitStream stream;
		stream.write_string(statistic_name);
		stream.write_u32(amount);

		CRules@ rules = getRules();
		rules.SendCommand(rules.getCommandID("client_add_statistic"), stream, player);
	}
}
