// Zombie Fortress zombie spawning

#define SERVER_ONLY

#include "ZombieSpawnPos.as";

shared class Spawn
{
	string name;
	int weight;        //higher number equals higher chance of being picked
	f32 difficulty;    //difficulty required to start spawning this
	f32 time_modifier; //removes this much weight from the spawn each day
	int weight_minimum; //amount of our weight that the spawn will always have no matter what

	Spawn(const string&in name, const int&in weight, const f32&in difficulty, const f32&in time_modifier, const int&in weight_minimum)
	{
		this.name = name;
		this.weight = weight + 1;
		this.difficulty = difficulty;
		this.time_modifier = time_modifier;
		this.weight_minimum = weight_minimum;
	}
}

// name - weight - difficulty requirement - time modifier - time modifier cap
const Spawn@[] spawns =
{
	Spawn("skeleton",      1000, 0.0f, 60.0f, 50),
	Spawn("zombie",        600,  0.4f, 10.0f, 60),
	Spawn("zombieknight",  150,  1.0f, 0.0f,  0),
	Spawn("greg",          35,   1.5f, 0.0f,  0),
	Spawn("wraith",        30,   2.0f, 0.0f,  0),
	Spawn("skelepede",     5,    3.0f, 0.0f,  0)
};

f32 game_difficulty = 1.0f;  //zombie spawnrate multiplier
u16 maximum_zombies = 400;   //maximum amount of zombies that can be on the map at once
u16 maximum_skelepedes = 4;  //maximum amount of skelepedes that can be on the map at once

int spawn_weights_sum = 0;

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
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		game_difficulty = cfg.exists("game_difficulty") ? cfg.read_f32("game_difficulty") : 1.0f;
		maximum_zombies = cfg.exists("maximum_zombies") ? cfg.read_u16("maximum_zombies") : 400;
		maximum_skelepedes = cfg.exists("maximum_skelepedes") ? cfg.read_u16("maximum_skelepedes") : 4;
	}
	
	//initialize spawn weights
	spawn_weights_sum = 0;
	for (u8 i = 0; i < spawns.length; i++)
	{
		spawn_weights_sum += spawns[i].weight;
	}
}

void onTick(CRules@ this)
{
	const u16 dayNumber = this.get_u16("day_number");
	if (dayNumber < 2) return;

	f32 difficulty;
	u32 spawnRate;
	getSpawnRates(dayNumber, spawnRate, difficulty);

	if (getGameTime() % spawnRate != 0) return;

	if (this.get_u16("undead count") >= maximum_zombies) return;

	CMap@ map = getMap();
	if (map.getDayTime() > 0.8f || map.getDayTime() < 0.1f)
	{
		SpawnZombie(map, dayNumber, difficulty);
	}
}

//Calculate our spawn rates and gamemode-difficulty based on the day number and amount of players on the server
void getSpawnRates(const u16&in dayNumber, u32&out spawnRate, f32&out difficulty, const u8&in playerCount = getPlayersCount())
{
	f32 player_modifier = (playerCount - 1) * 0.2f;
	player_modifier *= Maths::Min(1.0f, dayNumber / 5.0f); //lessen the impact of player count during early days (full effect is reached on day 5)

	const f32 difficulty_ramp = Maths::Pow(dayNumber * 0.25f, 1.0001f);

	difficulty = (difficulty_ramp + player_modifier) * game_difficulty * 0.85f;
	spawnRate = Maths::Max(getTicksASecond() / difficulty, 1);
}

//spown de zombe
void SpawnZombie(CMap@ map, const u16&in dayNumber, const f32&in difficulty)
{
	Spawn@ spawn;
	while(true)
	{
		Spawn@ random_spawn = GetRandomSpawn();
		if (random_spawn.difficulty > difficulty) continue;

		if (random_spawn.time_modifier > 0.0f)
		{
			//could be improved, it does the job though
			const int rand = XORRandom(random_spawn.weight);
			const int time_mod = Maths::Min(random_spawn.time_modifier * dayNumber, random_spawn.weight - random_spawn.weight_minimum);
			if (rand < time_mod) continue;
		}

		@spawn = random_spawn;
		break;
	}

	if (spawn.name == "skelepede")
	{
		//skelepedes spawn far underground
		CBlob@[] skelepedes;
		getBlobsByName("skelepede", @skelepedes);
		if (skelepedes.length < maximum_skelepedes)
		{
			Vec2f dim = map.getMapDimensions();
			Vec2f spawnpos(XORRandom(dim.x), dim.y + 50 + XORRandom(600));
			server_CreateBlob(spawn.name, -1, spawnpos);
		}
	}
	else if (spawn.name == "greg" || spawn.name == "wraith")
	{
		//flying enemies spawn at a random height at world edge
		Vec2f spawn_pos = getZombieSpawnPos(map);
		spawn_pos.y = XORRandom(spawn_pos.y);
		server_CreateBlob(spawn.name, -1, spawn_pos);
	}
	else
	{
		//everything else spawns on the ground at world edge
		server_CreateBlob(spawn.name, -1, getZombieSpawnPos(map));
	}
}

//Get a random zombie based on their weights
Spawn@ GetRandomSpawn()
{
	const int random_weight = XORRandom(spawn_weights_sum);
	int current_number = 0;

	for (u8 i = 0; i < spawns.length; i++)
	{
		Spawn@ spawn = spawns[i];
		if (random_weight <= current_number + spawn.weight)
		{
			return spawn;
		}

		current_number += spawn.weight;
	}

	return null;
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
			const u8 playerCount = tokens.length > 2 ? parseInt(tokens[2]) : getPlayersCount();
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
