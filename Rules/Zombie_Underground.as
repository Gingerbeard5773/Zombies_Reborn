//Zombie Underground

#include "CustomTiles.as";

const int refilldirt_ticks = 30;
const int refillores_ticks = 100;
const f32 ore_space_radius = 10.0f;
const f32 radsq = ore_space_radius * 8 * ore_space_radius * 8;
const Vec2f[] faces = { Vec2f(0, -8), Vec2f(0, 8), Vec2f(8, 0), Vec2f(-8, 0) };

void onInit(CRules@ this)
{
	
}

void onTick(CRules@ this)
{
	//if (getGameTime() % refill_ticks != 0) return;
	
	CMap@ map = getMap();
	Vec2f underground(0, 0);
	if (!map.getMarker("underground", underground)) return;
	
	int underground_depth = underground.y / map.tilesize;
	underground_depth += XORRandom(map.tilemapheight - underground_depth);
	Vec2f position = Vec2f(XORRandom(map.tilemapwidth), underground_depth);
	position *= map.tilesize;
	
	//if (map.getTile(position).type == CMap::tile_ground)
		//CreateDeposit(map, CMap::tile_stone, position, 10, 0);
		
	if (getGameTime() % refillores_ticks == 0)
		AreaCreateDeposit(map, position);

	if (getGameTime() % refilldirt_ticks == 0)
		AreaRefillDirt(map, position);

	/*Tile tile = map.getTile(position);
	if (tile.type == CMap::tile_ground)
	{
		for (u8 i = 0; i < 4; i++)
		{
			const u16 tiletype = map.getTile(position + directions[i]).type;

			if (isTileIronOre(tiletype))           { map.server_SetTile(position, CMap::tile_ironore);  return; }
			else if (isTileCoal(tiletype))         { map.server_SetTile(position, CMap::tile_coal);     return; }
			else if (map.isTileStone(tiletype))    { map.server_SetTile(position, CMap::tile_stone);    return; }
		}
	}*/
}

void AreaCreateDeposit(CMap@ map, Vec2f position)
{
	if (map.getTile(position).type != CMap::tile_ground) return;

	u32 stone_count = 0, iron_count = 0, coal_count = 0, gold_count = 0;
	for (int x_step = -ore_space_radius; x_step < ore_space_radius; ++x_step)
	{
		for (int y_step = -ore_space_radius; y_step < ore_space_radius; ++y_step)
		{
			Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
			if (off.LengthSquared() > radsq) continue;

			Vec2f tpos = position + off;
			Tile tile = map.getTile(tpos);
			if (map.isTileStone(tile.type))
				stone_count++;
			else if (isTileIronOre(tile.type))
				iron_count++;
			else if (isTileCoal(tile.type))
				coal_count++;
			else if (map.isTileGold(tile.type))
				gold_count++;
		}
	}
	if (XORRandom(5) == 0 && coal_count < 5)
		CreateDeposit(map, CMap::tile_coal, position, 3 + XORRandom(3), 0);
	else if (XORRandom(5) == 0 && iron_count < 7)
		CreateDeposit(map, CMap::tile_ironore, position, 5 + XORRandom(6), 0);
	else if (XORRandom(2) == 0 && stone_count < 15)
		CreateDeposit(map, CMap::tile_stone, position, 6 + XORRandom(8), 0);
	
}

void CreateDeposit(CMap@ map, const u16&in tiletype, Vec2f position, const u8&in amount, u8&in count)
{
	map.server_SetTile(position, CMap::tile_ironore); //hacky solution to keep tiles from making noises
	map.server_SetTile(position, tiletype);
	count++;
	if (amount < count) return;

	for (u8 i = 0; i < 4; i++)
	{
		Vec2f random_position = position + faces[XORRandom(4)];
		if (map.getTile(random_position).type == CMap::tile_ground)
		{
			CreateDeposit(map, tiletype, random_position, amount, count);
			break;
		}
	}
}

void AreaRefillDirt(CMap@ map, Vec2f position)
{
	if (!RefillDirt(map, position)) //check first position, if not applicable then check adjacent
	{
		for (u8 i = 0; i < 4; i++)
		{
			Vec2f check_pos = position + faces[XORRandom(4)];
			if (RefillDirt(map, check_pos))
				break;
		}
	}
}

bool RefillDirt(CMap@ map, Vec2f position)
{
	const int offset = map.getTileOffset(position);
	if (map.isTileBackground(map.getTile(offset)) && map.getTileDirt(offset) > 0)
	{
		Tile righttile = map.getTile(position + faces[3]);
		Tile lefttile = map.getTile(position + faces[2]);

		const bool under = map.isTileSolid(map.getTile(position + faces[1]));
		const bool left = map.isTileSolid(lefttile) && isTileGroundStuff(map, lefttile.type);
		const bool right = map.isTileSolid(righttile) && isTileGroundStuff(map, righttile.type);

		if (under && (left || right))
		{
			map.server_SetTile(position, CMap::tile_ironore); //hacky solution to keep tiles from making noises
			map.server_SetTile(position, CMap::tile_ground);
			return true;
		}
	}
	return false;
}



