// Swing Door logic

#include "Hitters.as"
#include "CustomTiles.as"

void onInit(CBlob@ this)
{
	//block knight sword
	this.Tag("blocks sword");

	this.set_TileType("background tile", CMap::tile_biron);

	if (isServer())
	{
		dictionary harvest;
		harvest.set('mat_iron', 5);
		this.set('harvest', harvest);
	}

	this.Tag("door");
	this.Tag("blocks water");
	this.Tag("explosion always teamkill"); // ignore 'no teamkill' for explosives
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::builder:
			damage *= 0.5f;
			break;
		case Hitters::bite:
			damage *= 0.55f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::bomb_arrow:
		case Hitters::mine:
			damage *= 0.5f;
			break;
		case Hitters::keg:
			damage *= 0.1f;
			break;
		default:
			break;
	}

	return damage;
}
