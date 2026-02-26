// Zombie Fortress zombie spawning

#define SERVER_ONLY

#include "Zombie_SpawnUndeadCommon.as"

SpawnManager@ manager;

f32 game_difficulty = 1.0f;  //zombie spawnrate multiplier
u16 maximum_zombies = 400;   //maximum amount of zombies that can be on the map at once

void onInit(CRules@ this)
{
	Reset(this);
}

void onReload(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	@manager = SpawnManager();
	
	Spawn@[] spawns =
	{
		SkeletonSpawn(     1000,  0.0f, -60.0f, 50),
		ZombieSpawn(        600,  0.4f, -10.0f, 60),
		ZombieKnightSpawn(  150,  1.0f),
		GregSpawn(           35,  1.5f),
		WraithSpawn(         30,  1.8f),
		DarkWraithSpawn(      8,  2.0f),
		HorrorSpawn(          5,  3.5f),
		SkelepedeSpawn(       3,  3.0f)
	};

	manager.Add(spawns);

	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		game_difficulty = cfg.exists("game_difficulty") ? cfg.read_f32("game_difficulty") : 1.0f;
		maximum_zombies = cfg.exists("maximum_zombies") ? cfg.read_u16("maximum_zombies") : 400;
		manager.maximum_skelepedes = cfg.exists("maximum_skelepedes") ? cfg.read_u16("maximum_skelepedes") : 4;
		manager.maximum_gregs = cfg.exists("maximum_gregs") ? cfg.read_u16("maximum_gregs") : 50;
	}
}

void onTick(CRules@ this)
{
	if (this.get_bool("pause_undead_spawns")) return;

	const u16 dayNumber = this.get_u16("day_number");
	if (dayNumber < 2) return;

	f32 difficulty;
	u32 spawnRate;
	getSpawnRates(dayNumber, spawnRate, difficulty, this.get_u8("survivor player count"));

	if (getGameTime() % spawnRate != 0) return;

	if (this.get_u16("undead count") >= maximum_zombies) return;

	CMap@ map = getMap();
	if (map.getDayTime() > 0.8f || map.getDayTime() < 0.1f)
	{
		manager.day_number = dayNumber;
		manager.difficulty = difficulty;
		manager.SpawnRandomUndead();
	}
}

//Calculate our spawn rates and gamemode-difficulty based on the day number and amount of players on the server
void getSpawnRates(const u16&in dayNumber, u32&out spawnRate, f32&out difficulty, const u8&in playerCount)
{
	f32 player_modifier = (playerCount - 1) * 0.2f;
	player_modifier *= Maths::Min(1.0f, dayNumber / 5.0f); //lessen the impact of player count during early days (full effect is reached on day 5)

	const f32 difficulty_ramp = Maths::Pow(dayNumber * 0.25f, 1.0001f);

	difficulty = (difficulty_ramp + player_modifier) * game_difficulty * 0.85f;
	spawnRate = Maths::Max(getTicksASecond() / difficulty, 1);
}

///DEBUGGING

//Prints out the calculated spawn rates for all days and players you put in. Very useful for testing.
void PrintSpawnRates(CRules@ this, const u8&in days_to_print, const u8&in playerCount)
{
	f32 difficulty;
	u32 spawnRate;
	print("---------");
	print("ZOMBIE SPAWN RATES USING "+playerCount+" PLAYERS");
	for (u8 i = 1; i < days_to_print + 1; i++) 
	{
		getSpawnRates(i, spawnRate, difficulty, playerCount);
		print("");
		print("Day "+i);
		print("  Spawn Rate: "+spawnRate);
		print("  Difficulty: "+difficulty);
	}
	print("---------");
}

//Related Chat commands
// !spawnrates [days to print] [player number]
// !difficulty [new difficulty]
bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	if (sv_test || player.isMod() || player.isRCON() || player.getUsername() == "MrHobo")
	{
		string[]@ tokens = text_in.split(" ");

		if (tokens.length > 1 && tokens[0] == "!spawnrates")
		{
			const u8 playerCount = tokens.length > 2 ? parseInt(tokens[2]) : getPlayerCount();
			PrintSpawnRates(this, parseInt(tokens[1]), playerCount);
			return false;
		}
		else if (tokens[0] == "!difficulty")
		{
			game_difficulty = tokens.length > 1 ? parseFloat(tokens[1]) : game_difficulty;
			print("Game Difficulty: "+game_difficulty);
			return false;
		}
	}
	return true;
}
