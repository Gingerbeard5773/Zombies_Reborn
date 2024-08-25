#include "Hitters.as"
#include "CustomTiles.as"

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(128) > 64);

	this.getShape().getConsts().waterPasses = true;

	CShape@ shape = this.getShape();
	shape.AddPlatformDirection(Vec2f(0, -1), 89, false);
	shape.SetRotationsAllowed(false);
	
	this.Tag("blocks sword");
	this.set_TileType("background tile", CMap::tile_biron);
	
	this.server_setTeamNum(-1);

	if (isServer())
	{
		dictionary harvest;
		harvest.set('mat_iron', 4);
		this.set('harvest', harvest);
	}

	MakeDamageFrame(this);
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	f32 hp = this.getHealth();
	bool repaired = (hp > oldHealth);
	MakeDamageFrame(this, repaired);
}

void MakeDamageFrame(CBlob@ this, bool repaired = false)
{
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	int frame_count = this.getSprite().animation.getFramesCount();
	int frame = frame_count - frame_count * (hp / full_hp);
	this.getSprite().animation.frame = frame;

	if (repaired)
	{
		this.getSprite().PlaySound("build_wall.ogg");
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("build_wall.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::builder:
			damage *= 0.8f;
			break;
		case Hitters::bite:
			damage *= 0.85f;
			break;
		case Hitters::bomb:
		case Hitters::explosion:
		case Hitters::mine:
			damage *= 0.5f;
			break;
		case Hitters::bomb_arrow:
			damage *= 0.2f;
			break;
		case Hitters::keg:
			damage *= 0.1f;
			break;
		default:
			break;
	}

	return damage;
}