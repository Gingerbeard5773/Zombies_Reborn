// Decide where zombies spawn
Vec2f getZombieSpawnPos(CMap@ map)
{
	Vec2f[] spawns;
	map.getMarkers("zombie_spawn", spawns);
	
	if (spawns.length <= 0)
	{
		Vec2f dim = map.getMapDimensions();
		const u32 margin = 10;
		const Vec2f offset = Vec2f(0, -8);
		
		Vec2f side;
		
		map.rayCastSolid(Vec2f(margin, 0.0f), Vec2f(margin, dim.y), side);
		spawns.push_back(side + offset);
		
		map.rayCastSolid(Vec2f(dim.x-margin, 0.0f), Vec2f(dim.x-margin, dim.y), side);
		spawns.push_back(side + offset);
	}
	
	return spawns[XORRandom(spawns.length)];
}
