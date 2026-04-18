//Custom Tiles
//Gingerbeard @ August 14, 2024
//v = variation   -  full health tile with a visual variation
//d = damaged     -  damage frame
//f = final       -  last tile before destroyed

namespace CMap
{
	enum CustomTile
	{
		tile_ironore = 384,
		tile_ironore_v0,
		tile_ironore_v1,
		tile_ironore_v2,
		tile_ironore_v3,
		tile_ironore_d0,
		tile_ironore_d1,
		tile_ironore_d2,
		tile_ironore_d3,
		tile_ironore_d4,
		tile_ironore_f,

		tile_coal = 400,
		tile_coal_v0,
		tile_coal_d0,
		tile_coal_d1,
		tile_coal_d2,
		tile_coal_d3,
		tile_coal_f,
		
		tile_iron = 432,
		tile_iron_v0,
		tile_iron_v1,
		tile_iron_v2,
		tile_iron_v3,
		tile_iron_v4,
		tile_iron_v5,
		tile_iron_v6,
		tile_iron_v7,
		tile_iron_v8,
		tile_iron_v9,
		tile_iron_v10,
		tile_iron_v11,
		tile_iron_v12,
		tile_iron_v13,
		tile_iron_v14,
		tile_iron_d0,
		tile_iron_d1,
		tile_iron_d2,
		tile_iron_d3,
		tile_iron_d4,
		tile_iron_d5,
		tile_iron_d6,
		tile_iron_d7,
		tile_iron_f,
		
		tile_biron = 464,
		tile_biron_v0,
		tile_biron_v1,
		tile_biron_v2,
		tile_biron_d0,
		tile_biron_d1,
		tile_biron_d2,
		tile_biron_d3,
		tile_biron_d4,
		tile_biron_d5,
		tile_biron_d6,
		tile_biron_d7,
		tile_biron_f,

		tile_goldblock = 489,
		tile_goldblock_v0,
		tile_goldblock_v1,
		tile_goldblock_v2,
		tile_goldblock_v3,
		tile_goldblock_v4,
		tile_goldblock_v5,
		tile_goldblock_d0,
		tile_goldblock_d1,
		tile_goldblock_d2,
		tile_goldblock_d3,
		tile_goldblock_d4,
		tile_goldblock_d5,
		tile_goldblock_d6,
		tile_goldblock_d7,
		tile_goldblock_d8,
		tile_goldblock_d9,
		tile_goldblock_d10,
		tile_goldblock_d11,
		tile_goldblock_d12,
		tile_goldblock_d13,
		tile_goldblock_d14,
		tile_goldblock_f,

		tile_bgoldblock = 512,
		tile_bgoldblock_v0,
		tile_bgoldblock_v1,
		tile_bgoldblock_d0,
		tile_bgoldblock_d1,
		tile_bgoldblock_d2,
		tile_bgoldblock_d3,
		tile_bgoldblock_d4,
		tile_bgoldblock_d5,
		tile_bgoldblock_d6,
		tile_bgoldblock_d7,
		tile_bgoldblock_d8,
		tile_bgoldblock_d9,
		tile_bgoldblock_d10,
		tile_bgoldblock_d11,
		tile_bgoldblock_f
	};
}

bool isTileIronOre(const u16&in tile)
{
	return tile >= CMap::tile_ironore && tile <= CMap::tile_ironore_f;
}

bool isTileCoal(const u16&in tile)
{
	return tile >= CMap::tile_coal && tile <= CMap::tile_coal_f;
}

bool isTileIron(const u16&in tile)
{
	return tile >= CMap::tile_iron && tile <= CMap::tile_iron_f;
}

bool isTileBIron(const u16&in tile)
{
	return tile >= CMap::tile_biron && tile <= CMap::tile_biron_f;
}

bool isTileGoldBlock(const u16&in tile)
{
	return tile >= CMap::tile_goldblock && tile <= CMap::tile_goldblock_f;
}

bool isTileBGoldBlock(const u16&in tile)
{
	return tile >= CMap::tile_bgoldblock && tile <= CMap::tile_bgoldblock_f;
}

//universal
bool isTileBetween(const u16&in tile, const u16&in min, const u16&in max)
{
	return tile >= min && tile <= max;
}

//engine replacement since the engine is garbage and cannot be modified script side
bool isTileSolid(CMap@ map, const u16&in tile)
{
	return map.isTileSolid(tile) || isTileIronOre(tile) || isTileCoal(tile) || isTileIron(tile) || isTileGoldBlock(tile);
}

bool isTileGroundStuff(CMap@ map, const u16&in tile)
{
	return map.isTileGroundStuff(tile) || isTileIronOre(tile) || isTileCoal(tile);
}

//tile tiers: mainly used in constructing/repairing tiles to decipher which tiles replace which other tiles

u8 getTileTierSolid(TileType tile)
{
	if (isTileBetween(tile, CMap::tile_wood_d1, CMap::tile_wood_d0))             return 0; //damaged wood block
	if (isTileBetween(tile, CMap::tile_castle_d1, CMap::tile_castle_d0))         return 1; //damaged castle
	if (tile == CMap::tile_wood)                                                 return 1; //wood
	if (tile == CMap::tile_castle)                                               return 2; //castle
	if (tile == CMap::tile_castle_moss)                                          return 2; //mossy castle
	if (isTileBetween(tile, CMap::tile_iron_d0, CMap::tile_iron_f))              return 2; //damaged iron
	if (isTileIron(tile))                                                        return 3; //iron
	if (isTileBetween(tile, CMap::tile_goldblock_d0, CMap::tile_goldblock_f))    return 3; //damaged gold
	if (isTileGoldBlock(tile))                                                   return 4; //gold block
	return 255;
}

u8 getTileTierBackground(TileType tile)
{
	if (tile == CMap::tile_wood_back)                                            return 1; //wood
	if (tile == CMap::tile_castle_back)                                          return 2; //castle
	if (tile == CMap::tile_castle_back_moss)                                     return 2; //mossy castle
	if (isTileBetween(tile, CMap::tile_biron_d0, CMap::tile_biron_f))            return 2; //damaged iron
	if (isTileBIron(tile))                                                       return 3; //iron
	if (isTileBetween(tile, CMap::tile_bgoldblock_d0, CMap::tile_bgoldblock_f))  return 3; //damaged gold
	if (isTileBGoldBlock(tile))                                                  return 4; //gold block
	return 0;
}
