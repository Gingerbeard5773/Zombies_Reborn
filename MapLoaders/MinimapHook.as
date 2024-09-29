///Minimap Code

//Gingerbeard: had to grab the legacy minimap from the engine to add in compatibility with custom tiles

///Legacy minimap

const SColor color_sky(0xffedcca6);
const SColor color_solid(0xffc4873a);
const SColor color_solid_border(0xff844715);
const SColor color_background(0xfff3ac5c);
const SColor color_background_border(0xffc4873a);
const SColor color_water(0xff2cafde);
const SColor color_fire(0xffd5543f);

void CalculateMinimapColour(CMap@ map, u32 offset, TileType type, SColor &out col)
{
	if (map.isTileSolid(map.getTile(offset)))
	{
		col = color_solid;

		if (!isMapBorder(map, offset))
		{
			if (!map.isTileSolid(map.getTile(offset - 1)) || 
			    !map.isTileSolid(map.getTile(offset + 1)) ||
			    !map.isTileSolid(map.getTile(offset - map.tilemapwidth)) ||
			    !map.isTileSolid(map.getTile(offset + map.tilemapwidth)))
			{
				col = color_solid_border;
			}
		}
	}
	else if (type != CMap::tile_empty && !map.isTileGrass(type))
	{
		col = color_background;

		if (!isMapBorder(map, offset))
		{
			if ((map.getTile(offset - 1).type == CMap::tile_empty) ||
			    (map.getTile(offset + 1).type == CMap::tile_empty) ||
			    (map.getTile(offset - map.tilemapwidth).type == CMap::tile_empty) ||
			    (map.getTile(offset + map.tilemapwidth).type == CMap::tile_empty))
			{
				col = color_background_border;
			}
		}
	}
	else
	{
		col = color_sky;
	}

	Vec2f pos = map.getTileWorldPosition(offset);
	if (map.isInWater(pos))
	{
		col = col.getInterpolated(color_water, 0.5f);
	}
	/*else if (map.isInFire(pos) && type != CMap::tile_empty)
	{
		col = col.getInterpolated(color_fire, 0.5f);
	}*/
}

bool isMapBorder(CMap@ map, const u32 &in offset)
{
	const bool LeftRight = offset % map.tilemapwidth == 0 || offset % map.tilemapwidth == map.tilemapwidth - 1;
	const bool TopBottom = offset < map.tilemapwidth || offset > map.tilemapwidth * map.tilemapheight - map.tilemapwidth;
	return LeftRight || TopBottom;
}
