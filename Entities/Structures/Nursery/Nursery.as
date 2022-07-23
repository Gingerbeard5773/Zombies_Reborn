// Nursery

#include "ProductionCommon.as";
#include "Requirements.as";
#include "MakeSeed.as";

void onInit(CBlob@ this)
{
	this.inventoryButtonPos = Vec2f(0.0f, 10.0f);
	this.Tag("builder always hit");
	this.set_TileType("background tile", CMap::tile_wood_back);
	
	this.getShape().getConsts().mapCollisions = false;
	this.set_string("produce sound", "/branches1");
	
	{
		addSeedItem(this, "grain_plant", "Grain plant seed", 60, 1);
	}
	{
		addSeedItem(this, "flowers", "Flowers seed", 20, 1);
	}
	
	this.Tag("inventory access");
	string[] autograb_blobs = {"seed"};
	this.set("autograb blobs", autograb_blobs);
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	this.getConsts().accurateLighting = true;

	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 40, 32);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		int[] frames = { 3, 4, 5 };
		anim.AddFrames(frames);
		front.SetRelativeZ(500);
	}
}
