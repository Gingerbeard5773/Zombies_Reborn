// Kitchen

#include "Requirements.as";
#include "CraftItemCommon.as"
#include "FireParticle.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.inventoryButtonPos = Vec2f(-8.0f, 0.0f);
	this.Tag("builder always hit");
	this.set_TileType("background tile", CMap::tile_castle_back);
	
	this.getShape().getConsts().mapCollisions = false;

	this.getCurrentScript().tickFrequency = 30; //once a second

	this.SetLight(false);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	/*
	{
		CBitStream requirements;
		AddRequirement(requirements, "blob", "grain", "Grain", 1);
		//AddRequirement(requirements, "blob", "builder", "Builder", 1);
		addFoodItem(this, "Cake", 5, "A cake made of a builder corpse.", 20, 1, @requirements);
	}
	{
		CBitStream requirements;
		AddRequirement(requirements, "blob", "grain", "Grain", 1);
		AddRequirement(requirements, "blob", "trader", "Russian", 1);
		addFoodItem(this, "Russian Burger", 6, "A hamburger made of a veiny old person.", 30, 1, @requirements);
	}*/
	
	Craft craft();
	craft.menu_size = Vec2f(5, 1);
	craft.button_offset = Vec2f(4, 0);
	craft.produce_sound = "Cooked.ogg";
	craft.icon_image = "Food.png";
	this.set("Craft", @craft); 
	
	{
		CraftItem i("bread", Translate::Bread+"\n$heart_full$$heart_half$", 4, 30);
		AddRequirement(i.reqs, "blob", "mat_flour", "Flour", 20);
		craft.addItem(this, i);
	}
	{
		CraftItem i("cake", Translate::Cake+"\n$heart_full$$heart_full$$heart_full$", 5, 30);
		AddRequirement(i.reqs, "blob", "mat_flour", "Flour", 15);
		AddRequirement(i.reqs, "blob", "egg", "Egg", 1);
		craft.addItem(this, i);
	}
	{
		CraftItem i("cookedfish", Translate::Cookedfish+"\n$heart_full$$heart_full$$heart_full$$heart_half$", 1, 30);
		AddRequirement(i.reqs, "blob", "fishy", "Fish", 1);
		craft.addItem(this, i);
	}
	{
		CraftItem i("cookedsteak", Translate::Cookedsteak+"\n$heart_full$$heart_full$$heart_full$$heart_full$", 0, 30);
		AddRequirement(i.reqs, "blob", "steak", "Steak", 1);
		craft.addItem(this, i);
	}
	{
		CraftItem i("food", Translate::Burger+"\n$heart_full$$heart_full$$heart_full$$heart_full$$heart_full$$heart_full$$heart_half$", 6, 30);
		AddRequirement(i.reqs, "blob", "steak", "Steak", 1);
		AddRequirement(i.reqs, "blob", "bread", "Bread", 1);
		craft.addItem(this, i);
	}
}

void onTick(CBlob@ this)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	this.SetLight(craft.time > 0);
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	this.getConsts().accurateLighting = true;
	this.getCurrentScript().tickFrequency = 15;
	this.SetEmitSound("CampfireSound.ogg");

	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 40, 32);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		int[] frames = { 3, 4, 5 };
		anim.AddFrames(frames);
		front.SetRelativeZ(500);
	}
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16);
	if (fire !is null)
	{
		Animation@ anim = fire.addAnimation("fire", 6, true);
		int[] frames = { 1, 2, 3 };
		anim.AddFrames(frames);
		fire.SetRelativeZ(1);
		fire.SetOffset(Vec2f(-9, 7));
		fire.SetVisible(false);
	}
	CSpriteLayer@ fire_bg = this.addSpriteLayer("fire_bg", this.getFilename(), 8, 8);
	if (fire_bg !is null)
	{
		Animation@ anim = fire_bg.addAnimation("default", 0, false);
		anim.AddFrame(120);
		fire_bg.SetOffset(Vec2f(-7, 9));
		fire_bg.SetVisible(false);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Craft@ craft = getCraft(blob);
	if (craft is null) return;

	CSpriteLayer@ fire_bg = this.getSpriteLayer("fire_bg");
	CSpriteLayer@ fire = this.getSpriteLayer("fire_animation_large");
	if (craft.time > 0)
	{
		this.SetEmitSoundPaused(false);
		fire.SetVisible(true);
		fire_bg.SetVisible(true);
		makeSmokeParticle(blob.getPosition() + Vec2f(7,-15));
	}
	else
	{
		if (!this.getEmitSoundPaused())
			this.SetEmitSoundPaused(true);
			
		fire.SetVisible(false);
		fire_bg.SetVisible(false);
	}
}
