// Armory

#include "Requirements.as"
#include "ShopCommon.as"
#include "TeamIconToken.as"
#include "StandardRespawnCommand.as"

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.Tag("builder always hit");

	InitClasses(this);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(-10, 0));
	this.set_Vec2f("shop menu size", Vec2f(3, 3));
	this.set_string("shop description", "Armory");
	this.set_u8("shop icon", 25);

	int team_num = this.getTeamNum();
	
	{
		ShopItem@ s = addShopItem(this, "Scythe", getTeamIcon("scythe", "Scythe.png", team_num, Vec2f(16, 25), 0), "scythe", "Scythe\nA tool for cutting crops fast. \nAllows for grain auto-pickup.", false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Crossbow", getTeamIcon("crossbow", "Crossbow.png", team_num, Vec2f(18, 14), 0), "crossbow", "Crossbow", false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 1);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Musket", getTeamIcon("musket", "Musket.png", team_num, Vec2f(30, 9), 0), "musket", "Musket", false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 70);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Musket Balls", "$mat_musketballs$", "mat_musketballs", "Musket Balls\nAmmunition for the Musket.", false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Chainsaw", getTeamIcon("chainsaw", "Chainsaw.png", team_num, Vec2f(32, 16), 0), "chainsaw", "Chainsaw", false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 1);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Molotov", "$molotov$", "molotov", "Molotov\nA flask of fire which can be thrown at the enemy. Space to activate.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 45);
	}
	/*{
		ShopItem@ s = addShopItem(this, "Blunderbuss", getTeamIcon("blunderbuss", "Blunderbuss.png", team_num, Vec2f(29, 9), 0), "blunderbuss", "Blunderbuss", false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 70);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}*/
}

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	this.getConsts().accurateLighting = true;

	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 56, 40);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		int[] frames = { 2, 3 };
		anim.AddFrames(frames);
		front.SetRelativeZ(500);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	const bool overlapping = this.getDistanceTo(caller) < this.getRadius();
	this.set_bool("shop available", overlapping);
	
	if (overlapping)	 
	{
		caller.CreateGenericButton("$change_class$", Vec2f(6, 0), this, buildSpawnMenu, getTranslatedString("Change class"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
	
	onRespawnCommand(this, cmd, params);
}
