//Zombie Fortress statistics

const string StatsFileName = "Zombie_Statistics.cfg";

ConfigFile@ openStatsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/"+StatsFileName))
	{
		warn("Creating statistics config ../Cache/"+StatsFileName);
		cfg.saveFile(StatsFileName);
	}

	return cfg;
}

u16 server_getRecordDay(const u16&in current_day, bool&out new_record)
{
	ConfigFile@ cfg = openStatsConfig();

	if (!cfg.exists("record_day")) cfg.add_u16("record_day", 1);

	new_record = false;
	u16 record_day = cfg.read_u16("record_day");
	if (current_day > record_day)
	{
		cfg.add_u16("record_day", current_day);
		record_day = current_day;
		new_record = true;
	}
	
	cfg.saveFile(StatsFileName);
	
	return record_day;
}

u16 server_getRecordDay()
{
	ConfigFile@ cfg = openStatsConfig();

	if (!cfg.exists("record_day")) return 1;

	return cfg.read_u16("record_day");
}

void getEndGameStatistics(CRules@ this, string[]@ inputs)
{
	int mostBlocks = 0;
	int mostKills = 0;
	int mostDeaths = 0;
	string mostBlocksPlayer = "N/A";
	string mostKillsPlayer = "N/A";
	string mostDeathsPlayer = "N/A";

	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		if (player.getScore() > mostBlocks)
		{
			mostBlocks = player.getScore();
			mostBlocksPlayer = player.getCharacterName();
		}
		
		if (player.getKills() > mostKills)
		{
			mostKills = player.getKills();
			mostKillsPlayer = player.getCharacterName();
		}
		
		if (player.getDeaths() > mostDeaths)
		{
			mostDeaths = player.getDeaths();
			mostDeathsPlayer = player.getCharacterName();
		}
	}
	
	inputs.push_back(this.get_u32("score_undead_killed_total")+"");
	inputs.push_back(mostBlocksPlayer);
	inputs.push_back(mostKillsPlayer);
	inputs.push_back(mostDeathsPlayer);
	inputs.push_back(server_getRecordDay()+"");
}
