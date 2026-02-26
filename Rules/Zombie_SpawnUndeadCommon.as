// Zombie Fortress zombie spawning common

#include "ZombieSpawnPos.as"
#include "GetSurvivors.as"

class SpawnManager
{
	Spawn@[] spawns;
	
	u16 day_number = 1;
	f32 difficulty = 1.0f;
	u16 maximum_skelepedes = 4;
	u16 maximum_gregs = 50;
	
	SpawnManager() {}

	void Add(Spawn@ spawn)
	{
		spawns.push_back(spawn);
		@spawn.manager = @this;
	}

	void Add(Spawn@[]@ other_spawns)
	{
		for (u8 i = 0; i < other_spawns.length; i++)
		{
			Add(other_spawns[i]);
		}
	}
	
	void SpawnRandomUndead()
	{
		Spawn@ spawn = GetRandomSpawn();
		if (spawn is null) return;

		spawn.CreateBlob();
	}
	
	Spawn@ GetRandomSpawn()
	{
		Spawn@[] valid;
		f32 total_weight = 0.0f;

		for (u8 i = 0; i < spawns.length; i++)
		{
			Spawn@ spawn = spawns[i];

			if (!spawn.canSpawn()) continue;

			f32 weight = getWeight(spawn);
			if (weight <= 0.0f) continue;

			total_weight += weight;
			valid.push_back(spawn);
		}

		if (total_weight <= 0.0f)
		{
			error("Failed to spawn undead : No remaining weight.");
			return null;
		}

		f32 r = XORRandom(total_weight * 1000) / 1000.0f;

		for (u8 i = 0; i < valid.length; i++)
		{
			Spawn@ spawn = valid[i];
			f32 w = getWeight(spawn);

			if (r <= w) return spawn;

			r -= w;
		}

		return null;
	}

	f32 getWeight(Spawn@ spawn)
	{
		f32 scaled = spawn.weight + (day_number * spawn.growth);
		return Maths::Max(spawn.weight_min, scaled);
	}
}

class Spawn
{
	string name;
	f32 weight;         //higher number equals higher chance of being picked
	f32 weight_min;     //amount of our weight that the spawn will always have no matter what
	f32 difficulty_min; //difficulty required to start spawning this
	f32 growth;         //changes the weight based on game difficulty
	
	SpawnManager@ manager;

	Spawn(string name, f32 weight, f32 difficulty_min, f32 growth = 1.0f, f32 weight_min = 0.0f)
	{
		this.name = name;
		this.weight = weight + 1;
		this.difficulty_min = difficulty_min;
		this.growth = growth;
		this.weight_min = weight_min;
	}
	
	bool canSpawn()
	{
		return difficulty_min < manager.difficulty;
	}
	
	void CreateBlob()
	{
		server_CreateBlob(name, -1, getZombieSpawnPos(getMap()));
	}
}

class SkeletonSpawn : Spawn
{
	SkeletonSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("skeleton", weight, difficulty_min, growth, weight_min);
	}
}

class ZombieSpawn : Spawn
{
	ZombieSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("zombie", weight, difficulty_min, growth, weight_min);
	}
}

class ZombieKnightSpawn : Spawn
{
	ZombieKnightSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("zombieknight", weight, difficulty_min, growth, weight_min);
	}
}

class HorrorSpawn : Spawn
{
	HorrorSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("horror", weight, difficulty_min, growth, weight_min);
	}
}

/// Fliers

class FlierSpawn : Spawn
{
	FlierSpawn(string name, f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super(name, weight, difficulty_min, growth, weight_min);
	}
	
	void CreateBlob()
	{
		//flying enemies spawn at a random height at world edge
		Vec2f spawn_pos = getZombieSpawnPos(getMap());
		spawn_pos.y = XORRandom(spawn_pos.y);
		server_CreateBlob(name, -1, spawn_pos);
	}
}

class GregSpawn : FlierSpawn
{
	GregSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("greg", weight, difficulty_min, growth, weight_min);
	}
	
	bool canSpawn()
	{
		if (!Spawn::canSpawn()) return false;

		CBlob@[] gregs;
		getBlobsByName("greg", @gregs);
		return gregs.length < manager.maximum_gregs;
	}
}

class WraithSpawn : FlierSpawn
{
	WraithSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("wraith", weight, difficulty_min, growth, weight_min);
	}
}

class DarkWraithSpawn : FlierSpawn
{
	DarkWraithSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("darkwraith", weight, difficulty_min, growth, weight_min);
	}

	void CreateBlob()
	{
		CRules@ rules = getRules();
		const u16 day_number = rules.get_u16("day_number");
		const u16 player_count = rules.get_u8("survivor player count");
		const u32 difficulty = (day_number * 5) + (player_count * 2);
		const u32 probability = 450 - Maths::Min(difficulty, 450);
		if (XORRandom(probability) == 0) name = "jerry";

		FlierSpawn::CreateBlob();
		name = "darkwraith";
	}
}

class JerrySpawn : FlierSpawn
{
	JerrySpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("jerry", weight, difficulty_min, growth, weight_min);
	}
}

/// Skelepedes

class SkelepedeSpawn : Spawn
{
	SkelepedeSpawn(f32 weight, f32 difficulty_min, f32 growth = 0.0f, f32 weight_min = 0.0f)
	{
		super("skelepede", weight, difficulty_min, growth, weight_min);
	}
	
	bool canSpawn()
	{
		if (!Spawn::canSpawn()) return false;

		CBlob@[] skelepedes;
		getBlobsByName(name, @skelepedes);
		if (skelepedes.length >= manager.maximum_skelepedes) return false;

		CBlob@[] survivors = getSurvivors();
		if (survivors.length <= 0) return true;
		
		CMap@ map = getMap();
		
		//identify random player
		//if said player is underground, the skelepede has a 1/10 chance of spawning
		CBlob@ survivor = survivors[XORRandom(survivors.length)];
		Vec2f survivor_pos = survivor.getPosition();
		if (!map.isBelowLand(survivor_pos)) return true;

		//player must have at least 4 solid tiles over their head to be 'underground'
		u8 ground_count = 0;
		for (u8 i = 0; i < 50; i++)
		{
			survivor_pos -= Vec2f(0, 8);
			Tile tile = map.getTile(survivor_pos);
			if (tile.dirt != 80) return true;

			if (map.isTileSolid(tile))
			{
				if (ground_count++ >= 4) return XORRandom(10) == 0;
			}
		}
		return true;
	}
	
	void CreateBlob()
	{
		//skelepedes spawn far underground
		Vec2f dim = getMap().getMapDimensions();
		Vec2f spawnpos(XORRandom(dim.x), dim.y + 50 + XORRandom(600));
		server_CreateBlob(name, -1, spawnpos);
	}
}
