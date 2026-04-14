// Zombie Fortress NPC spawn calculator

#include "PathingNodesCommon.as"

funcdef f32 SpawnCostHandle(Vec2f);

Vec2f getSpawnLocation(Vec2f&in spawn_area, const f32&in radius, CBlob@[]@ blobs, SpawnCostHandle@ SpawnCost)
{
	Vec2f[] origins;
	for (int i = 0; i < blobs.length; ++i)
	{
		origins.push_back(blobs[i].getPosition());
	}

	return getSpawnLocation(spawn_area, radius, origins, @SpawnCost);
}

Vec2f getSpawnLocation(Vec2f&in spawn_area, const f32&in radius, Vec2f[]@ origins, SpawnCostHandle@ SpawnCost)
{
	if (origins.length == 0) return Vec2f_zero;

	HighLevelNode@[]@ nodeMap;
	if (!getRules().get("node_map", @nodeMap)) return Vec2f_zero;

	f32 best_cost = 999999.0f;
	Vec2f best_pos = origins[0];

	for (int attempt = 0; attempt < 40; attempt++)
	{
		Vec2f origin = origins[XORRandom(origins.length)];

		HighLevelNode@[] nodes = getNodesInRadius(origin, radius, nodeMap, Path::GROUND);
		if (nodes.length == 0) continue;

		Vec2f pos = nodes[XORRandom(nodes.length)].position;

		const f32 cost = !isValidSpawnArea(pos, spawn_area) ? 10000.0f : SpawnCost(pos);
		if (cost < best_cost)
		{
			best_cost = cost;
			best_pos = pos;
		}
	}

	return best_pos;
}

bool isValidSpawnArea(Vec2f&in pos, Vec2f&in spawn_area)
{
	CMap@ map = getMap();
	// ensure spawn has ground underneath
	if (!map.isTileSolid(map.getTile(pos + Vec2f(halfsize, tilesize))) &&
	    !map.isTileSolid(map.getTile(pos + Vec2f(-halfsize, tilesize))))
	{
		return false;
	}

	// bottom center alignment
	Vec2f origin = pos - Vec2f((spawn_area.x * tilesize) / 2, spawn_area.y * tilesize);
	origin += Vec2f(halfsize, halfsize);

	for (int x = 0; x < int(spawn_area.x); x++)
	{
		for (int y = 0; y < int(spawn_area.y); y++)
		{
			Vec2f checkPos = origin + Vec2f(x * tilesize, y * tilesize);

			//CParticle@ p = ParticlePixel(checkPos, Vec2f_zero, color_white, true, 90);
			//if (p !is null) p.gravity = Vec2f_zero;

			if (map.isTileSolid(map.getTile(checkPos)) || map.isInWater(checkPos))
			{
				return false;
			}
		}
	}

	return true;
}


/// Standard Costs

f32 getStandardSpawnCost(Vec2f pos)
{
	f32 cost = 0.0f;
	cost += getTouchingBlobsSpawnCost(pos);
	cost += getDistanceSpawnCost(pos);
	cost += XORRandom(50);

	return cost;
}

f32 getDistanceSpawnCost(Vec2f pos)
{
	f32 distance_penalty = Maths::Abs(64.0f - pos.Length()); 
	return distance_penalty * 0.1f;
}

f32 getTouchingBlobsSpawnCost(Vec2f pos)
{
	f32 cost = 0.0f;
	CBlob@[] nearby;
	getMap().getBlobsInRadius(pos, 24.0f, @nearby);

	for (int i = 0; i < nearby.length; i++)
	{
		CBlob@ b = nearby[i];
		if (b.getName() == "grain_plant" || b.hasTag("tree"))
		{
			cost += 15.0f; continue;
		}

		if (b.hasTag("building"))
		{
			cost += 10.0f; continue;
		}

		if (b.getName() == "saw")
		{
			cost += 50.0f; continue;
		}
	}
	return cost;
}

f32 getNearbyUndeadSpawnCost(Vec2f pos)
{
	f32 cost = 0.0f;
	CBlob@[] nearby;
	getMap().getBlobsInRadius(pos, 150.0f, @nearby);

	for (int i = 0; i < nearby.length; i++)
	{
		CBlob@ b = nearby[i];
		if (b.hasTag("undead"))
		{
			f32 distance = (pos - b.getPosition()).Length();
			f32 distance_penalty = Maths::Max(150.0f - distance, 0.0f) * 0.25f;

			cost += distance_penalty + 25.0f; continue;
		}
	}
	return cost;
}
