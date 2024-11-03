//Zombie Fortress player structure saving

#define SERVER_ONLY

#include "CustomTiles.as";

const string FileName = "Zombie_Structures.cfg";

ConfigFile@ openStructuresConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/"+FileName))
	{
		warn("Creating structures config ../Cache/"+FileName);
		cfg.saveFile(FileName);
	}

	return cfg;
}

void onInit(CRules@ this)
{
	
}

void onRestart(CRules@ this)
{
	
}

class StructureTile
{
	Vec2f position;
	u16 type;
	StructureTile(Vec2f position, const u16&in type)
	{
		this.position = position;
		this.type = type;
	}
}

void SaveStructureFromPosition(Vec2f startPos)
{
	Vec2f[] tile_positions;
	u16[] tile_types;
	GetStructureFromPosition(startPos, tile_positions, tile_types);
	if (tile_positions.length == 0) return;

	Vec2f minPos = tile_positions[0].position;
	Vec2f maxPos = tile_positions[0].position;

	//determine bounding box
	for (u16 i = 1; i < tile_positions.length; i++)
	{
		Vec2f pos = tile_positions[i];
		if (pos.x < minPos.x) minPos.x = pos.x;
		if (pos.y < minPos.y) minPos.y = pos.y;
		if (pos.x > maxPos.x) maxPos.x = pos.x;
		if (pos.y > maxPos.y) maxPos.y = pos.y;
	}

	Vec2f centerPos = (minPos + maxPos) * 0.5f;

	//offset from center in tile units
	for (u16 i = 0; i < tile_positions.length; i++)
	{
		tile_positions[i] -= centerPos;
		tile_positions[i] /= 8;
	}
	
	print("Adding new structure to "+FileName+" | SIZE : "+tile_positions.length);
	
	ConfigFile@ cfg = openStructuresConfig();
	const u16 structures_count = (cfg.exists("structures_count") ? cfg.read_u16("structures_count") : 0) + 1;
	cfg.add_u16("structures_count", structures_count);
	
	cfg.addArray_Vec2f(structures_count + "_positions", tile_positions);
	cfg.addArray_u16(structures_count + "_types", tile_types);
}

void GetStructureFromPosition(Vec2f startPos, Vec2f[]@ tile_positions, u16[]@ tile_types)
{
	CMap@ map = getMap();

	Vec2f[] toExplore = { startPos };
	dictionary visited;

	while (toExplore.length() > 0)
	{
		Vec2f currentPos = toExplore[toExplore.length() - 1];
		toExplore.pop_back();

		if (visited.exists(currentPos.toString())) continue;
		visited.set(currentPos.toString(), true);

		u16 type = map.getTile(currentPos).type;
		if (!isStructureTile(map, type, type)) continue;

		tile_positions.push_back(currentPos);
		tile_types.push_back(type);

		Vec2f[] adjacent =
		{
			currentPos + Vec2f(0, -8),
			currentPos + Vec2f(0, 8),
			currentPos + Vec2f(-8, 0),
			currentPos + Vec2f(8, 0)
		};

		for (u8 i = 0; i < adjacent.length(); i++)
		{
			Vec2f adjacentPos = adjacent[i];
			if (!visited.exists(adjacentPos.toString()))
			{
				toExplore.push_back(adjacentPos);
			}
		}
	}
}

bool isStructureTile(CMap@ map, const u16&in type, u16&out new_type)
{
	new_type = type;
	if (map.isTileCastle(type)) return true;
	if (map.isTileWood(type)) return true;
	if (type >= CMap::tile_castle_back && type <= 79) return true;
	if (type >= CMap::tile_wood_back && type <= 207) return true;

	if (isTileIron(type))
	{
		new_type = CMap::tile_castle;
		return true;
	}

	if (isTileBIron(type))
	{
		new_type = CMap::tile_castle_back;
		return true;
	}
	return false;
}
