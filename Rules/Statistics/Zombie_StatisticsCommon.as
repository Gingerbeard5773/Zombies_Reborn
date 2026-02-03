//Zombie Fortress Statistics
// Gingerbeard @ Jan 30, 2026

// statistics dont clear on restart on server

// fix zombies merging causing undead killed stat to increment

#include "Zombie_Translation.as"

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

	const string filename = "Zombie_Statistics.cfg";
	const string current = "_current";
	const string alltime = "_alltime";

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

	u32 Get(const string&in statistic_name, ConfigFile@ cfg = openConfig())
	{
		const u32 stat = cfg.exists(statistic_name) ? cfg.read_u32(statistic_name) : 0;
		return stat;
	}

	void Add(const string&in statistic_name, const u32&in amount, ConfigFile@ cfg = openConfig())
	{
		const u32 current_stat = cfg.exists(statistic_name + current) ? cfg.read_u32(statistic_name + current) : 0;
		const u32 alltime_stat = cfg.exists(statistic_name + alltime) ? cfg.read_u32(statistic_name + alltime) : 0;

		cfg.add_u32(statistic_name + current, amount + current_stat);
		cfg.add_u32(statistic_name + alltime, amount + alltime_stat);

		cfg.saveFile(filename);
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
