// Wind Mill

#include "Upgrades.as";

const u32 conversion_seconds = 30;

void onInit(CBlob@ this)
{
	this.inventoryButtonPos = Vec2f(0, 24);
	this.Tag("builder always hit");
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getShape().getConsts().mapCollisions = false;
	
	this.set_Vec2f("pull_items_button_offset", Vec2f(0, -6));
	
	string[] pull_names = { "grain" };
	this.set("pull_items", pull_names);
	
	this.addCommandID("sv_store");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (blob.getName() == "grain")
	{
		this.server_PutInInventory(blob);
	}
}

void onTick(CBlob@ this)
{
	const f32 millpow = this.get_f32("mill power");

	CBlob@ grain = this.getInventory().getItem("grain");
	if (grain !is null)
	{
		this.set_f32("mill power", Maths::Min(millpow + millpow/100 + 0.002f, 5));
		
		//grind grain into flour
		if (getGameTime() % (conversion_seconds * getTicksASecond()) == (this.getNetworkID() % 30))
		{
			convertToFlour(this, grain);
		}
	}
	else
	{
		this.set_f32("mill power", Maths::Max(millpow - millpow/110 - 0.0001f, 0));
	}
	
	CSprite@ sprite = this.getSprite();
	if (millpow > 0.5f)
	{
		if (sprite.getEmitSoundPaused())
			sprite.SetEmitSoundPaused(false);
	}
	else
	{
		sprite.SetEmitSoundPaused(true);
	}
}

void convertToFlour(CBlob@ this, CBlob@ grain)
{
	if (isServer())
	{
		CBlob@ flour = server_CreateBlobNoInit("mat_flour");
		if (flour is null) return;
		flour.Tag("custom quantity");
		flour.Init();
		const u16 quantity = (10 + XORRandom(7)) * getMillingPercent();
		flour.server_SetQuantity(quantity);
		
		grain.server_Die();
		
		//if (!this.server_PutInInventory(flour))
			flour.setPosition(this.getPosition() + Vec2f(4, 24));
	}
	
	this.getSprite().PlaySound("StoreSound.ogg");
}

f32 getMillingPercent()
{
	f32 percent = 1.0f;
	u32[]@ upgrades = getUpgrades();
	if (hasUpgrade(upgrades, Upgrade::Milling))    percent += 0.10f;
	if (hasUpgrade(upgrades, Upgrade::MillingII))  percent += 0.10f;
	if (hasUpgrade(upgrades, Upgrade::MillingIII)) percent += 0.15f;
	
	return percent;
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "grain")
		this.getSprite().PlaySound("/PopIn");
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!isInventoryAccessible(this, caller)) return;

	CInventory@ inv = caller.getInventory();
	if (inv is null) return;
	
	if (inv.getItem("grain") !is null)
	{
		CButton@ button = caller.CreateGenericButton(28, Vec2f(0, 0), this, this.getCommandID("sv_store"), "Store");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sv_store") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			if (item.getName() == "grain")
			{
				caller.server_PutOutInventory(item);
				this.server_PutInInventory(item);
				i--;
			}
		}
	}
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background

	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 48, 37);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		anim.AddFrame(2);
		front.SetOffset(Vec2f(0, 18));
		front.SetRelativeZ(500);
	}
	CSpriteLayer@ back = this.addSpriteLayer("back layer", this.getFilename(), 48, 37);
	if (back !is null)
	{
		Animation@ anim = back.addAnimation("default", 0, false);
		anim.AddFrame(0);
		back.SetOffset(Vec2f(0, 18));
		back.SetRelativeZ(0);
	}
	CSpriteLayer@ tower = this.addSpriteLayer("tower", this.getFilename(), 32, 59);
	if (tower !is null)
	{
		Animation@ anim = tower.addAnimation("default", 0, false);
		anim.AddFrame(3);
		tower.SetOffset(Vec2f(0, -22));
		tower.SetRelativeZ(-1);
	}
	CSpriteLayer@ windmill = this.addSpriteLayer("windmill", "WindMill.png", 64, 64);
	if (windmill !is null)
	{
		Animation@ anim = windmill.addAnimation("default", 0, false);
		anim.AddFrame(0);
		windmill.SetOffset(Vec2f(0, -34));
		windmill.SetRelativeZ(5);
	}
	CSpriteLayer@ pole = this.addSpriteLayer("pole", "Mill.png", 8, 12);
	if (pole !is null)
	{
		Animation@ anim = pole.addAnimation("default", 5, true);
		int[] frames = {8, 9, 10, 11};
		anim.AddFrames(frames);
		pole.SetOffset(Vec2f(-10, 21));
		pole.SetRelativeZ(1);
	}
	CSpriteLayer@ grinder0 = this.addSpriteLayer("grinder0", "Mill.png", 12, 3);
	if (grinder0 !is null)
	{
		Animation@ anim = grinder0.addAnimation("default", 4, true);
		int[] frames = {56, 55, 46, 45};
		anim.AddFrames(frames);
		grinder0.SetOffset(Vec2f(-10, 29));
		grinder0.SetRelativeZ(1.1f);
	}
	CSpriteLayer@ grinder1 = this.addSpriteLayer("grinder1", "Mill.png", 12, 3);
	if (grinder1 !is null)
	{
		Animation@ anim = grinder1.addAnimation("default", 4, true);
		int[] frames = {45, 46, 55, 56};
		anim.AddFrames(frames);
		grinder1.SetOffset(Vec2f(-10, 32));
		grinder1.SetRelativeZ(1.2f);
	}
	
	this.SetEmitSound("/Quarry.ogg");
	this.SetEmitSoundPaused(true);
}

void onTick(CSprite@ this)
{
	CBlob@ mill = this.getBlob();
	const f32 millpow = mill.get_f32("mill power");
	const u8 animtime = millpow < 0.5f ? 0 : 8 - millpow;
	
	CSpriteLayer@ windmill = this.getSpriteLayer("windmill");
	windmill.RotateBy(millpow*(this.isFacingLeft() ? -1 : 1), Vec2f());
	
	CSpriteLayer@ pole = this.getSpriteLayer("pole");
	{
		Animation@ anim	= pole.getAnimation("default");
		anim.time = Maths::Round(animtime);
	}
	CSpriteLayer@ grinder0 = this.getSpriteLayer("grinder0");
	{
		Animation@ anim	= grinder0.getAnimation("default");
		anim.time = Maths::Round(animtime);
	}
	CSpriteLayer@ grinder1 = this.getSpriteLayer("grinder1");
	{
		Animation@ anim	= grinder1.getAnimation("default");
		anim.time = Maths::Round(animtime);
	}
}
