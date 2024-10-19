// loads a classic KAG .PNG map

#include "BasePNGLoader.as";
#include "ProceduralGeneration.as";
#include "MinimapHook.as";
#include "CustomTiles.as";

namespace custom_colors
{
	enum color
	{
		ironore = 0xff705648,
		coal = 0xff2E2E2E,
		steel = 0xff879092,
		iron = 0xff6B7273,
		biron = 0xff3F4141
	};
}

class ZombiePNGLoader : PNGLoader
{
	ZombiePNGLoader()
	{
		super();
	}
	
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);
		switch (pixel.color)
		{
			case custom_colors::ironore:  map.SetTile(offset, CMap::tile_ironore + XORRandom(4)); break;
			case custom_colors::coal:     map.SetTile(offset, CMap::tile_coal + XORRandom(2));    break;
			case custom_colors::steel:    map.SetTile(offset, CMap::tile_steel);                  break;
			case custom_colors::iron:     map.SetTile(offset, CMap::tile_iron);                   break;
			case custom_colors::biron:    map.SetTile(offset, CMap::tile_biron);                  break;
		};
	}
};

bool LoadMap(CMap@ map, const string& in fileName)
{
	ZombiePNGLoader loader();

	map.legacyTileMinimap = false;
	
	bool procedural_map_gen = true;
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		procedural_map_gen = cfg.exists("procedural_map_gen") ? cfg.read_bool("procedural_map_gen") : true;
	}

	int map_seed = Time();
	CRules@ rules = getRules();
	if (rules.exists("new map seed"))
	{
		const int new_map_seed = rules.get_s32("new map seed");
		if (new_map_seed > -1)
		{
			map_seed = new_map_seed;
			rules.set_s32("new map seed", -1);
			procedural_map_gen = true;
		}
	}
	
	if (procedural_map_gen)
	{
		print("LOADING PROCEDURALLY GENERATED MAP - MAP SEED: "+map_seed, 0xff66C6FF);
		return loadProceduralGenMap(map, map_seed);
	}

	print("LOADING ZOMBIES MAP " + fileName, 0xff66C6FF);
	return loader.loadMap(map, fileName);
}

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	if (isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
		if (blob !is null)
		{
			blob.server_Die();
		}
	}

	return true;
}

TileType server_onTileHit(CMap@ map, f32 damage, u32 index, TileType oldTileType)
{
	if (map.getTile(index).type > 255)
	{
		switch(oldTileType)
		{
			// IRON ORE //
			case CMap::tile_ironore:
			case CMap::tile_ironore_v0:
			case CMap::tile_ironore_v1:
			case CMap::tile_ironore_v2:
			case CMap::tile_ironore_v3:
				return CMap::tile_ironore_d0;

			case CMap::tile_ironore_d0:
			case CMap::tile_ironore_d1:
			case CMap::tile_ironore_d2:
			case CMap::tile_ironore_d3:
			case CMap::tile_ironore_d4:
				return oldTileType + 1;

			case CMap::tile_ironore_f:
				return CMap::tile_empty;


			// COAL //
			case CMap::tile_coal:
			case CMap::tile_coal_v0:
				return CMap::tile_coal_d0;

			case CMap::tile_coal_d0:
			case CMap::tile_coal_d1:
			case CMap::tile_coal_d2:
			case CMap::tile_coal_d3:
				return oldTileType + 1;

			case CMap::tile_coal_f:
				return CMap::tile_empty;


			// STEEL //
			case CMap::tile_steel:
			case CMap::tile_steel_d0:
			case CMap::tile_steel_d1:
			case CMap::tile_steel_d2:
			case CMap::tile_steel_d3:
			case CMap::tile_steel_d4:
			case CMap::tile_steel_d5:
			case CMap::tile_steel_d6:
				return oldTileType + 1;

			case CMap::tile_steel_f:
				return CMap::tile_empty;
				
			
			// IRON //
			case CMap::tile_iron:
				return CMap::tile_iron_d0;

			case CMap::tile_iron_v0:
			case CMap::tile_iron_v1:
			case CMap::tile_iron_v2:
			case CMap::tile_iron_v3:
			case CMap::tile_iron_v4:
			case CMap::tile_iron_v5:
			case CMap::tile_iron_v6:
			case CMap::tile_iron_v7:
			case CMap::tile_iron_v8:
			case CMap::tile_iron_v9:
			case CMap::tile_iron_v10:
			case CMap::tile_iron_v11:
			case CMap::tile_iron_v12:
			case CMap::tile_iron_v13:
			case CMap::tile_iron_v14:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE);
				return CMap::tile_iron_d0;

			case CMap::tile_iron_d0:
			case CMap::tile_iron_d1:
			case CMap::tile_iron_d2:
			case CMap::tile_iron_d3:
			case CMap::tile_iron_d4:
			case CMap::tile_iron_d5:
			case CMap::tile_iron_d6:
			case CMap::tile_iron_d7:
				return oldTileType + 1;

			case CMap::tile_iron_f:
				return CMap::tile_empty;
			
			
			// IRON BACKGROUND //
			case CMap::tile_biron:
				return CMap::tile_biron_d0;
			
			case CMap::tile_biron_v0:
			case CMap::tile_biron_v1:
			case CMap::tile_biron_v2:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::WATER_PASSES | Tile::LIGHT_PASSES);
				map.RemoveTileFlag(index, Tile::LIGHT_SOURCE | Tile::SOLID | Tile::COLLISION);
				return CMap::tile_biron_d0;

			case CMap::tile_biron_d0:
			case CMap::tile_biron_d1:
			case CMap::tile_biron_d2:
			case CMap::tile_biron_d3:
			case CMap::tile_biron_d4:
			case CMap::tile_biron_d5:
			case CMap::tile_biron_d6:
			case CMap::tile_biron_d7:
				return oldTileType + 1;

			case CMap::tile_biron_f:
				return CMap::tile_empty;
		};
	}
	return map.getTile(index).type;
}

void onSetTile(CMap@ map, u32 index, TileType tile_new, TileType tile_old)
{
	//dummy tile logic moved here from LoaderUtilities.as
	if (isDummyTile(tile_new))
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case Dummy::SOLID:
			case Dummy::OBSTRUCTOR:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			case Dummy::BACKGROUND:
			case Dummy::OBSTRUCTOR_BACKGROUND:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				break;
			case Dummy::LADDER:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::LADDER | Tile::WATER_PASSES);
				break;
			case Dummy::PLATFORM:
				map.AddTileFlag(index, Tile::PLATFORM);
				break;
		}
	}

	//if (tile_new == CMap::tile_ground)
	//{
		//if (isClient()) Sound::Play("dig_dirt" + (1 + XORRandom(3)) + ".ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
	//}
	
	//check if tile was destroyed
	if (tile_new == CMap::tile_empty || tile_new == CMap::tile_ground_back)
	{
		switch(tile_old)
		{
			case CMap::tile_ironore_f: OnIronOreTileDestroyed(map, index); break;
			case CMap::tile_coal_f:    OnCoalTileDestroyed(map, index);    break;
			case CMap::tile_steel_f:   OnSteelTileDestroyed(map, index);   break;
			case CMap::tile_iron_f:    OnIronTileDestroyed(map, index);    break;
			case CMap::tile_biron_f:   OnBIronTileDestroyed(map, index);   break;
		};
	}

	if (map.getTile(index).type > 255)
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			// IRON ORE //
			case CMap::tile_ironore:
			case CMap::tile_ironore_v0:
			case CMap::tile_ironore_v1:
			case CMap::tile_ironore_v2:
			case CMap::tile_ironore_v3:
				map.SetTileSupport(index, 255); //do not allow this block to collapse
				map.SetTileDirt(index, 80); //put dirt background underneath the block
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_ironore_d0:
			case CMap::tile_ironore_d1:
			case CMap::tile_ironore_d2:
			case CMap::tile_ironore_d3:
			case CMap::tile_ironore_d4:
			case CMap::tile_ironore_f:
				OnIronOreTileHit(map, index);
				break;


			// COAL //
			case CMap::tile_coal:
			case CMap::tile_coal_v0:
				map.SetTileSupport(index, 255); //do not allow this block to collapse
				map.SetTileDirt(index, 80); //put dirt background underneath the block
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_coal_d0:
			case CMap::tile_coal_d1:
			case CMap::tile_coal_d2:
			case CMap::tile_coal_d3:
			case CMap::tile_coal_f:
				OnCoalTileHit(map, index);
				break;


			// STEEL //
			case CMap::tile_steel:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;

			case CMap::tile_steel_d0:
			case CMap::tile_steel_d1:
			case CMap::tile_steel_d2:
			case CMap::tile_steel_d3:
			case CMap::tile_steel_d4:
			case CMap::tile_steel_d5:
			case CMap::tile_steel_d6:
			case CMap::tile_steel_f:
				OnSteelTileHit(map, index);
				break;
				
			
			// IRON //
			case CMap::tile_iron:
			{
				Vec2f pos = map.getTileWorldPosition(index);
				SetTileFaces(map, pos, CMap::tile_iron, CMap::tile_iron_v14, directions_all);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				if (isClient()) Sound::Play("build_wall.ogg", pos, 1.0f, 1.0f);
				break;
			}
			
			case CMap::tile_iron_v0:
			case CMap::tile_iron_v1:
			case CMap::tile_iron_v2:
			case CMap::tile_iron_v3:
			case CMap::tile_iron_v4:
			case CMap::tile_iron_v5:
			case CMap::tile_iron_v6:
			case CMap::tile_iron_v7:
			case CMap::tile_iron_v8:
			case CMap::tile_iron_v9:
			case CMap::tile_iron_v10:
			case CMap::tile_iron_v11:
			case CMap::tile_iron_v12:
			case CMap::tile_iron_v13:
			case CMap::tile_iron_v14:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_iron_d0:
			case CMap::tile_iron_d1:
			case CMap::tile_iron_d2:
			case CMap::tile_iron_d3:
			case CMap::tile_iron_d4:
			case CMap::tile_iron_d5:
			case CMap::tile_iron_d6:
			case CMap::tile_iron_d7:
			case CMap::tile_iron_f:
				UpdateTileFaces(map, map.getTileWorldPosition(index), CMap::tile_iron, CMap::tile_iron_v14, directions_all);
				OnIronTileHit(map, index);
				break;
				
			
			// IRON BACKGROUND //
			case CMap::tile_biron:
				SetTileFaces(map, map.getTileWorldPosition(index), CMap::tile_biron, CMap::tile_biron_v2, directions_up_down);
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::WATER_PASSES | Tile::LIGHT_PASSES);
				map.RemoveTileFlag(index, Tile::LIGHT_SOURCE | Tile::SOLID | Tile::COLLISION);
				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;

			case CMap::tile_biron_v0:
			case CMap::tile_biron_v1:
			case CMap::tile_biron_v2:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;

			case CMap::tile_biron_d0:
			case CMap::tile_biron_d1:
			case CMap::tile_biron_d2:
			case CMap::tile_biron_d3:
			case CMap::tile_biron_d4:
			case CMap::tile_biron_d5:
			case CMap::tile_biron_d6:
			case CMap::tile_biron_d7:
			case CMap::tile_biron_f:
				UpdateTileFaces(map, map.getTileWorldPosition(index), CMap::tile_biron, CMap::tile_biron_v2, directions_up_down);
				OnBIronTileHit(map, index);
				break;
		};
	}
}


///IRON ORE

void OnIronOreTileHit(CMap@ map, const u32&in index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient()) Sound::Play("dig_stone" + (1 + XORRandom(3)) + ".ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}

void OnIronOreTileDestroyed(CMap@ map, const u32&in index)
{
	if (isClient()) Sound::Play("destroy_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}


///COAL

void OnCoalTileHit(CMap@ map, const u32&in index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient()) Sound::Play("dig_stone" + (1 + XORRandom(3)) + ".ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}

void OnCoalTileDestroyed(CMap@ map, const u32&in index)
{
	if (isClient()) Sound::Play("destroy_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
	if (isClient()) Sound::Play("Rubble"+(1+XORRandom(2))+".ogg", map.getTileWorldPosition(index), 0.5f, 1.0f);
}


/// STEEL

void OnSteelTileHit(CMap@ map, const u32&in index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient()) Sound::Play("dig_stone1.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}

void OnSteelTileDestroyed(CMap@ map, const u32&in index)
{
	if (isClient()) Sound::Play("destroy_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}


/// IRON

void OnIronTileHit(CMap@ map, const u32&in index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient()) Sound::Play("dig_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}

void OnIronTileDestroyed(CMap@ map, const u32&in index)
{
	if (isClient()) Sound::Play("destroy_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}


/// IRON BACKGROUND

void OnBIronTileHit(CMap@ map, const u32&in index)
{
	map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);

	if (isClient()) Sound::Play("dig_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}

void OnBIronTileDestroyed(CMap@ map, const u32&in index)
{
	if (isClient()) Sound::Play("destroy_stone.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
}


///GENERIC

const Vec2f[] directions_all = { Vec2f(0, -8), Vec2f(0, 8), Vec2f(8, 0), Vec2f(-8, 0) };
const Vec2f[] directions_up_down = { Vec2f(0, -8), Vec2f(0, 8) };

u8 getTileFaces(CMap@ map, Vec2f pos, const u16&in min, const u16&in max, const Vec2f[]@ directions)
{
	u8 mask = 0;
	for (u8 i = 0; i < directions.length; i++)
	{
		const u16 tile = map.getTile(pos + directions[i]).type;
		if (isTileBetween(tile, min, max)) mask |= 1 << i;
	}
	return mask;
}

void SetTileFaces(CMap@ map, Vec2f pos, const u16&in min, const u16&in max, const Vec2f[]@ directions)
{
	map.SetTile(map.getTileOffset(pos), min + getTileFaces(map, pos, min, max, directions));
	UpdateTileFaces(map, pos, min, max, directions);
}

void UpdateTileFaces(CMap@ map, Vec2f pos, const u16&in min, const u16&in max, const Vec2f[]@ directions)
{
	for (u8 i = 0; i < directions.length; i++)
	{
		Vec2f tilepos = pos + directions[i];
		if (isTileBetween(map.getTile(tilepos).type, min, max))
			map.SetTile(map.getTileOffset(tilepos), min + getTileFaces(map, tilepos, min, max, directions));
	}
}
