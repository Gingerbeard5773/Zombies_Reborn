///Minimap Code

namespace Minimap
{
	enum color
	{
		color_sky = 0xffA5BDC8,
		color_dirt = 0xff844715,
		color_dirt_backwall = 0xff3B1406,
		color_stone = 0xff8B6849,
		color_thickstone = 0xff42484B,
		color_gold = 0xffFEA53D,
		color_bedrock = 0xff2D342D,
		color_wood = 0xffC48715,
		color_wood_backwall = 0xff552A11,
		color_castle = 0xff637160,
		color_castle_backwall = 0xff313412,
		color_water = 0xff2cafde,
		color_fire = 0xffd5543f,

		color_ironore = 0xff705648,
		color_coal = 0xff2E2E2E,
		color_steel = 0xff879092,
		color_iron = 0xff6B7273,
		color_biron = 0xff3F4141,
		
		color_underground = 0xff272D27
	};
}

void CalculateMinimapColour(CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	///Colours

	if (tile == CMap::tile_empty)        col = Minimap::color_sky;
	else if (map.isTileGround(tile))     col = Minimap::color_dirt;
	else if (map.isTileBedrock(tile))    col = Minimap::color_bedrock;
	else if (map.isTileStone(tile))      col = Minimap::color_stone;
	else if (map.isTileThickStone(tile)) col = Minimap::color_thickstone;
	else if (map.isTileGold(tile))       col = Minimap::color_gold;
	else if (map.isTileWood(tile))       col = Minimap::color_wood;
	else if (map.isTileCastle(tile))     col = Minimap::color_castle;
	else if (isTileIronOre(tile))        col = Minimap::color_ironore;
	else if (isTileCoal(tile))           col = Minimap::color_coal;
	else if (isTileSteel(tile))          col = Minimap::color_steel;
	else if (isTileIron(tile))           col = Minimap::color_iron;
	else if (isTileBIron(tile))          col = Minimap::color_biron;

	else if (map.isTileBackgroundNonEmpty(map.getTile(offset)) && !map.isTileGrass(tile))
	{                  
		if (tile == CMap::tile_castle_back)       col = Minimap::color_castle_backwall;
		else if (tile == CMap::tile_wood_back)    col = Minimap::color_wood_backwall;
		else                                      col = Minimap::color_dirt_backwall;
	}
	else
	{
		col = Minimap::color_sky;
	}

	Vec2f pos = map.getTileWorldPosition(offset);

	///Tint the map based on Fire/Water State
	if (map.isInWater(pos))
	{
		col = col.getInterpolated(Minimap::color_water, 0.5f);
	}

	/*Vec2f underground;
	if (map.getMarker("underground", underground))
	{
		underground.y -= 10 * map.tilesize;
		if (pos.y >= underground.y)
		{
			const f32 depth = (pos.y - underground.y) / map.tilesize * 0.09f;
			col = col.getInterpolated(Minimap::color_underground, 1.0f - depth);
		}
	}*/
	/*else if (map.isInFire(pos))
	{
		col = col.getInterpolated(color_fire, 0.5f);
	}*/
}
