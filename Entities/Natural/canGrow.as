//common "can a plant grow at this tile" code

#include "Zombie_TechnologyCommon.as";
#include "CustomTiles.as";

bool isNotTouchingOthers(CBlob@ this)
{
	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return true;

	for (u16 i = 0; i < overlapping.length; i++)
	{
		CBlob@ blob = overlapping[i];
		if (blob.getName() == "seed" || blob.getName() == "tree_bushy" || blob.getName() == "tree_pine")
		{
			return false;
		}
	}

	return true;
}

bool canGrowAt(CBlob@ this, Vec2f&in pos)
{
	if (!this.getShape().isStatic()) // they can be static from grid placement
	{
		if (!this.isOnGround() || this.isInWater() || this.isAttached() || !isNotTouchingOthers(this))
		{
			return false;
		}
	}

	CMap@ map = getMap();
	if (map.getSectorAtPosition(pos, "no build") !is null)
	{
		return false;
	}

	return canGrowOnTile(this, pos, map);
}

bool canGrowOnTile(CBlob@ this, Vec2f&in pos, CMap@ map)
{
	Vec2f underneath = Vec2f(pos.x, pos.y + (this.getHeight() + map.tilesize) * 0.5f);
	TileType tile = map.getTile(underneath).type;

	string name = this.getName();
	if (name == "seed") name = this.get_string("seed_grow_blobname");

	if ((name == "tree_bushy" || name == "tree_pine") && hasTech(Tech::HardyTrees))
	{
		return isTileGroundStuff(map, tile);
	}
	else if (name == "grain_plant" && hasTech(Tech::HardyWheat))
	{
		return isTileGroundStuff(map, tile);
	}

	return map.isTileGround(tile);
}
