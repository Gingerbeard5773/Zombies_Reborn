// Gold Door logic

#include "Hitters.as"
#include "CustomTiles.as"

void onInit(CBlob@ this)
{
	this.Tag("iron_resistance");

	this.set_TileType("background tile", CMap::tile_bgoldblock);

	if (isServer())
	{
		dictionary harvest;
		harvest.set('mat_gold', 1);
		this.set('harvest', harvest);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::builder:
			damage *= 1.0f;
			break;
		case Hitters::bite:
			damage *= 0.5f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::bomb_arrow:
		case Hitters::mine:
			damage *= 0.4f;
			break;
		case Hitters::keg:
			damage *= 0.07f;
			break;
	}

	return damage;
}
