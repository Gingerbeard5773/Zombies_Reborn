//Zombie Fortress player structures

//Gingerbeard @ November 4, 2024

#include "CustomTiles.as";

Vec2f[] adjacent = { Vec2f(0, -8), Vec2f(0, 8), Vec2f(-8, 0), Vec2f(8, 0) };

const u16 minimum_structure_size = 40;
const u16 maximum_structure_size = 500;
const u16 tile_background = 144; 
const string structures_file = "Zombie_Structures.cfg";

ConfigFile@ openStructuresConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/"+structures_file))
	{
		warn("Creating structures config ../Cache/"+structures_file);
		cfg.saveFile(structures_file);
	}

	return cfg;
}

bool GetStructureFromConfig(string[]@ tile_offsets, string[]@ tile_types, const u16&in custom_index = 0)
{
	ConfigFile@ cfg = openStructuresConfig();

	const u16 structures_count = cfg.exists("count") ? cfg.read_u16("count") : 0;
	if (structures_count == 0) return false;

	//use random index if we didnt define a particular one
	const u16 index = custom_index > 0 ? custom_index : XORRandom(structures_count) + 1;
	const string structure_offsets = index+"p";
	const string structure_types = index+"t";

	if (!cfg.exists(structure_offsets)) { error("Failed to access structure offsets! ["+index+"]"); return false; }
	if (!cfg.exists(structure_types))   { error("Failed to access structure types! ["+index+"]");   return false; }

	cfg.readIntoArray_string(tile_offsets, structure_offsets);
	cfg.readIntoArray_string(tile_types, structure_types);

	if (tile_types.length != tile_offsets.length) { error("Structure size mismatch! ["+index+"]"); return false; }

	return true;
}

bool LoadStructureToWorld(CMap@ map, Vec2f start_pos, const u16&in custom_index = 0)
{
	string[] tile_offsets;
	string[] tile_types;
	if (!GetStructureFromConfig(@tile_offsets, @tile_types, custom_index)) return false;

	Vec2f map_dimensions = map.getMapDimensions();
	for (u16 i = 0; i < tile_offsets.length; i++)
	{
		const string[]@ tokens = tile_offsets[i].split(",");
		if (tokens.length != 2) continue;

		Vec2f tile_offset(parseFloat(tokens[0]), parseFloat(tokens[1]));
		Vec2f tile_position = start_pos + (tile_offset * 8);
		if (tile_position.x < 0 || tile_position.y < 16) continue;
		if (tile_position.x >= map_dimensions.x || tile_position.y >= map_dimensions.y) continue;

		Tile tile = map.getTile(tile_position);
		if (tile.type == CMap::tile_bedrock) continue;

		u16 type = parseInt(tile_types[i]);
		if (type == tile_background)
		{
			type = tile.dirt == 80 ? CMap::tile_ground_back : CMap::tile_empty;
		}
		map.server_SetTile(tile_position, type);
	}
	return true;
}

bool LoadStructureToWorld(CMap@ map, Vec2f start_pos, Vec2f world_dimensions, s16[][]@ World, Vec2f&out end_pos)
{
	string[] tile_offsets;
	string[] tile_types;
	if (!GetStructureFromConfig(@tile_offsets, @tile_types)) return false;

	Vec2f tile_position = start_pos;
	for (u16 i = 0; i < tile_offsets.length; i++)
	{
		const string[]@ tokens = tile_offsets[i].split(",");
		if (tokens.length != 2) continue;

		Vec2f tile_offset(Maths::Ceil(parseFloat(tokens[0])), Maths::Ceil(parseFloat(tokens[1])));
		tile_position = start_pos + tile_offset;
		if (tile_position.x < 0 || tile_position.y < 2) continue;
		if (tile_position.x >= world_dimensions.x || tile_position.y >= world_dimensions.y) continue;

		u16 tile = World[tile_position.x][tile_position.y];
		if (tile == CMap::tile_bedrock) continue;

		u16 type = parseInt(tile_types[i]);
		if (type == tile_background)
		{
			if (!isTileGroundStuff(map, tile) && tile != CMap::tile_ground_back) continue;

			type = CMap::tile_ground_back;
		}
		if (type >= CMap::tile_castle_back && type <= 79) type = CMap::tile_castle_back;
		if (type >= CMap::tile_wood_back && type <= 207)  type = CMap::tile_wood_back;
		World[tile_position.x][tile_position.y] = type;
	}
	end_pos = tile_position;
	return true;
}

bool LoadStructureToWorld(CMap@ map, Vec2f start_pos, Vec2f world_dimensions, s16[][]@ World)
{
	return LoadStructureToWorld(map, start_pos, world_dimensions, World, start_pos);
}

void LoadChainedStructureToWorld(CMap@ map, Vec2f start_pos, Vec2f world_dimensions, s16[][]@ World, const u16&in amount = 1)
{
	Vec2f end_pos = start_pos;
	for (u16 i = 0; i < amount; i++)
	{
		LoadStructureToWorld(map, end_pos, world_dimensions, @World, end_pos);
	}
}

bool SaveStructureAtPosition(Vec2f start_pos)
{
	print("Attempting to save structure at position : "+(start_pos / 8).toString());

	Vec2f[] tile_offsets;
	string[] tile_types;
	GetStructureFromPosition(start_pos, tile_offsets, tile_types);
	if (tile_offsets.length < minimum_structure_size || tile_offsets.length > maximum_structure_size) return false;

	Vec2f minPos = tile_offsets[0];
	Vec2f maxPos = tile_offsets[0];

	//determine bounding box
	for (u16 i = 1; i < tile_offsets.length; i++)
	{
		Vec2f pos = tile_offsets[i];
		if (pos.x < minPos.x) minPos.x = pos.x;
		if (pos.y < minPos.y) minPos.y = pos.y;
		if (pos.x > maxPos.x) maxPos.x = pos.x;
		if (pos.y > maxPos.y) maxPos.y = pos.y;
	}

	Vec2f structureSize = (maxPos - minPos) / 8;
	Vec2f centerPos = (minPos + maxPos) * 0.5f;

	string[] tile_offset_strings;

	//offset from center in tile units
	for (u16 i = 0; i < tile_offsets.length; i++)
	{
		tile_offsets[i] -= centerPos;
		tile_offsets[i] /= 8;
		
		const string offset_string = tile_offsets[i].x+","+tile_offsets[i].y;
		tile_offset_strings.push_back(offset_string);
	}

	ConfigFile@ cfg = openStructuresConfig();
	const u16 structures_count = (cfg.exists("count") ? cfg.read_u16("count") : 0) + 1;
	cfg.add_u16("count", structures_count);
	
	//string arrays are the only cfg function that doesnt crash, what a fucking terrible engine.
	cfg.addArray_string(structures_count + "p", tile_offset_strings);
	cfg.addArray_string(structures_count + "t", tile_types);
	cfg.saveFile(structures_file);

	print("Attempt Successful! New structure saved to "+structures_file+" | SIZE : "+tile_offsets.length);

	return true;
}

void GetStructureFromPosition(Vec2f start_pos, Vec2f[]@ tile_offsets, string[]@ tile_types)
{
	CMap@ map = getMap();

	Vec2f[] toExplore = { start_pos };
	dictionary visited;

	while (toExplore.length() > 0)
	{
		if (tile_offsets.length > maximum_structure_size) break;

		Vec2f currentPos = toExplore[toExplore.length() - 1];
		toExplore.pop_back();

		const string position_key = currentPos.toString();
		if (visited.exists(position_key)) continue;
		visited.set(position_key, true);

		u16 type = map.getTile(currentPos).type;
		
		//logic that stops holes from filling up 
		if (type == CMap::tile_empty || map.isTileGroundBack(type))
		{
			u8 adjacent_count = 0;
			for (u8 i = 0; i < 4; i++)
			{
				Vec2f adjacentPos = currentPos + adjacent[i];
				u16 adjacent_type = map.getTile(adjacentPos).type;
				if (!isStructureTile(map, adjacent_type, adjacent_type)) continue;

				if (++adjacent_count >= 2) break;
			}

			if (adjacent_count >= 2)
			{	
				tile_offsets.push_back(currentPos);
				tile_types.push_back(tile_background+"");
			}
			continue;
		}
		//end of anti-hole-fill logic

		if (!isStructureTile(map, type, type)) continue;

		tile_offsets.push_back(currentPos);
		tile_types.push_back(type+"");

		for (u8 i = 0; i < 4; i++)
		{
			Vec2f adjacentPos = currentPos + adjacent[i];
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
	if (map.isTileCastle(type))                       return true;
	if (type >= CMap::tile_castle_back && type <= 79) return true;
	if (map.isTileWood(type))                         return true;
	if (type >= CMap::tile_wood_back && type <= 207)  return true;

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
