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

		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("closed");
		sprite.PlaySound("door_close.ogg");
		sprite.SetRelativeZ(600);
		MakeDamageFrame(this);

		if (isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
		}
	}

	void Deactivate(CBlob@ this)
	{
		this.getShape().getConsts().collidable = false;

		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("open");
		sprite.PlaySound("door_close.ogg");
		sprite.SetRelativeZ(0);
		MakeDamageFrame(this);
		
		for (u16 i = 0; i < this.getTouchingCount(); i++)
		{
			this.getTouchingByIndex(i).AddForce(Vec2f_zero); // forces collision checks again
		}

		if (isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::BACKGROUND);
		}
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

	this.getShape().getConsts().collidable = false;
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

		getMap().server_SetTile(this.getPosition(), Dummy::BACKGROUND);
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-50);
	sprite.SetFacingLeft(false);
	MakeDamageFrame(this);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onDie(CBlob@ this)
{
	if (isServer() && this.getShape().isStatic())
	{
		getMap().server_SetTile(this.getPosition(), CMap::tile_empty);
	}
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

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch(customData)
	{
		case Hitters::bomb:
		case Hitters::explosion:
			damage *= 7.5f;
			break;
	}
	
	return damage;
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_bool(this.getShape().getConsts().collidable);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	bool collidable;
	if (!stream.saferead_bool(collidable)) return false;

	this.getShape().getConsts().collidable = collidable;

	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation(collidable ? "closed" : "open");
	sprite.SetRelativeZ(collidable ? 600 : 0);
	MakeDamageFrame(this);

	return true;
}
