
//script for a chicken

#include "AnimalConsts.as"

int g_lastSoundPlayedTime = 0;
int g_layGoldInterval = 0;

//sprite

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	f32 x = Maths::Abs(blob.getVelocity().x);
	if (blob.isAttached())
	{
		AttachmentPoint@ ap = blob.getAttachmentPoint(0);
		if (ap !is null && ap.getOccupied() !is null)
		{
			if (Maths::Abs(ap.getOccupied().getVelocity().y) > 0.2f)
			{
				this.SetAnimation("fly");
			}
			else
				this.SetAnimation("idle");
		}
	}
	else if (!blob.isOnGround())
	{
		this.SetAnimation("fly");
	}
	else if (x > 0.02f)
	{
		this.SetAnimation("walk");
	}
	else
	{
		if (this.isAnimationEnded())
		{
			uint r = XORRandom(20);
			if (r == 0)
				this.SetAnimation("peck_twice");
			else if (r < 5)
				this.SetAnimation("peck");
			else
				this.SetAnimation("idle");
		}
	}
}

//blob

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	this.set_f32("bite damage", 0.25f);

	//brain
	this.set_u8(personality_property, SCARED_BIT);
	this.getBrain().server_SetActive(true);
	this.set_f32(target_searchrad_property, 30.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 14);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);
	this.Tag("flesh");

	// movement
	AnimalVars@ vars;
	if (!this.get("vars", @vars)) return;
	vars.walkForce.Set(1.0f, -0.1f);
	vars.runForce.Set(2.0f, -1.0f);
	vars.slowForce.Set(1.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -20.0f);
	vars.maxVelocity = 1.1f;

	g_lastSoundPlayedTime = 0;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("flesh");
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft(x < 0);
	}
	else if (this.isKeyPressed(key_left))
	{
		this.SetFacingLeft(true);
	}
	else if (this.isKeyPressed(key_right))
	{
		this.SetFacingLeft(false);
	}

	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachmentPoint(0);
		if (point !is null)
		{
			CBlob@ occupied = point.getOccupied();
			if (occupied !is null)
			{
				Vec2f vel = occupied.getVelocity();
				if (vel.y > 0.5f)
				{
					occupied.AddForce(Vec2f(0, -20));
				}
			}
		}
	}
	else if (!this.isOnGround())
	{
		Vec2f vel = this.getVelocity();
		if (vel.y > 0.5f)
		{
			this.AddForce(Vec2f(0, -10));
		}
	}
	else if (XORRandom(128) == 0)
	{
		if (isClient() && g_lastSoundPlayedTime + 30 < getGameTime())
		{
			this.getSprite().PlaySound("/Pluck");
			g_lastSoundPlayedTime = getGameTime();
		}

		if (isServer() && ++g_layGoldInterval % 20 == 0)
		{
			CBlob@ gold = server_CreateBlobNoInit("mat_gold");
			if (gold !is null)
			{
				gold.setPosition(this.getPosition());
				gold.Tag('custom quantity');
				gold.Init();
				gold.server_SetQuantity(5 + XORRandom(3));
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!isClient()) return;

	if (blob is null || !blob.hasTag("flesh")) return;

	if (blob.getRadius() > this.getRadius() && g_lastSoundPlayedTime + 25 < getGameTime())
	{
		this.getSprite().PlaySound("/ScaredChicken");
		g_lastSoundPlayedTime = getGameTime();
	}
}
