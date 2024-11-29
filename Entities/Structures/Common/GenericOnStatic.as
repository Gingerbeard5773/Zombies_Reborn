//Gingerbeard @ November 28, 2024

void onSetStatic(CBlob@ this, const bool isStatic)
{
	this.getShape().SetTileValue_Legacy();
}

void onDie(CBlob@ this)
{
	//allow water to flow on our custom background tiles again
	if (this.getShape().isStatic())
	{
		CMap@ map = getMap();
		const u32 index = map.getTileOffset(this.getPosition());
		Tile tile = map.getTile(index);
		if (map.isTileBackground(tile))
		{
			map.AddTileFlag(index, Tile::WATER_PASSES);
		}
	}
}
