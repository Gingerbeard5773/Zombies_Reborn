// Nursery

#include "FactoryProductionCommon.as";

void onInit(CBlob@ this)
{
	this.inventoryButtonPos = Vec2f(0.0f, 10.0f);
	this.Tag("builder always hit");
	this.set_TileType("background tile", CMap::tile_wood_back);
	
	this.getShape().getConsts().mapCollisions = false;
	this.set_string("produce sound", "/branches1");
	
	this.set_bool("can produce", true);
	
	Production nursery("Nursery", 0);
	nursery.addProductionItem("grain_plant", "Grain plant seed", "", 60, 1, Product::seed);
	nursery.addProductionItem("flowers", "Flowers seed", "$flowers_icon$", 20, 1, Product::seed);
	nursery.ResetProduction();
	
	this.set("production", @nursery);
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
