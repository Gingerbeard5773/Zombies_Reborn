// Obstructor.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";
#include "Hitters.as";

class Obstructor : Component
{
	u16 id;

	Obstructor(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;
		id = _id;
	}

	void Activate(CBlob@ this)
	{
		this.getShape().getConsts().collidable = true;
		//this.getShape().getConsts().lightPasses = false;
		//this.getShape().getConsts().waterPasses = false;
		//this.Tag("blocks water");

		/*if (isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
		}*/

		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("closed");
		sprite.PlaySound("door_close.ogg");
		MakeDamageFrame(this);
	}

	void Deactivate(CBlob@ this)
	{
		this.getShape().getConsts().collidable = false;
		//this.getShape().getConsts().lightPasses = true;
		//this.getShape().getConsts().waterPasses = true;
		//this.Untag("blocks water");

		for (u16 i = 0; i < this.getTouchingCount(); i++)
		{
			this.getTouchingByIndex(i).AddForce(Vec2f_zero); // forces collision checks again
		}

		/*if (isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR_BACKGROUND);
		}*/

		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("open");
		sprite.PlaySound("door_close.ogg");
		MakeDamageFrame(this);
	}
}


void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	this.set_TileType("background tile", CMap::tile_castle_back);

	// used by DummyOnStatic.as
	//this.set_TileType(Dummy::TILE, Dummy::OBSTRUCTOR_BACKGROUND);

	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().collidable = false;
	//this.getShape().getConsts().waterPasses = true;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Obstructor component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-50);
	sprite.SetFacingLeft(false);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	MakeDamageFrame(this);
}

void MakeDamageFrame(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	const f32 hp = this.getHealth();
	const f32 full_hp = this.getInitialHealth();
	if (hp < full_hp)
	{
		const f32 ratio = hp / full_hp;
		if (ratio <= 0.0f)
		{
			sprite.animation.frame = sprite.animation.getFramesCount() - 1;
		}
		else
		{
			sprite.animation.frame = (1.0f - ratio) * (sprite.animation.getFramesCount());
		}
	}
}
