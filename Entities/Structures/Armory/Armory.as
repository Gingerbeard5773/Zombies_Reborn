// Armory

#include "Requirements.as"
#include "ShopCommon.as"
#include "TeamIconToken.as"
#include "StandardRespawnCommand.as"
#include "Zombie_Translation.as"

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.Tag("builder always hit");

	InitClasses(this);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(-10, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 5));
	this.set_string("shop description", name(Translate::Armory));
	this.set_u8("shop icon", 25);

	int team_num = this.getTeamNum();
	
	{
		ShopItem@ s = addShopItem(this, name(Translate::Scythe), getTeamIcon("scythe", "Scythe.png", team_num, Vec2f(16, 25), 0), "scythe", Translate::Scythe, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", name(Translate::IronIngot), 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Crossbow), getTeamIcon("crossbow", "Crossbow.png", team_num, Vec2f(18, 14), 0), "crossbow", Translate::Crossbow, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", name(Translate::IronIngot), 1);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Musket), getTeamIcon("musket", "Musket.png", team_num, Vec2f(30, 9), 0), "musket", Translate::Musket, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 70);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::MusketBalls), "$mat_musketballs$", "mat_musketballs", Translate::MusketBalls, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", name(Translate::IronIngot), 1);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Chainsaw), getTeamIcon("chainsaw", "Chainsaw.png", team_num, Vec2f(32, 16), 0), "chainsaw", Translate::Chainsaw, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 1);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::ScubaGear), "$scubagear$", "scubagear", Translate::ScubaGear, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", name(Translate::IronIngot), 3);
		AddRequirement(s.requirements, "coin", "", "Coins", 75);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::HeadLamp), "$headlamp$", "headlamp", Translate::HeadLamp, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", name(Translate::IronIngot), 2);
		AddRequirement(s.requirements, "blob", "lantern", "Lantern", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::SteelDrill), getTeamIcon("steeldrill", "SteelDrill.png", team_num, Vec2f(32, 16), 0), "steeldrill", Translate::SteelDrill, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 2);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::SteelHelmet), getTeamIcon("steelhelmet", "SteelHelmet.png", team_num, Vec2f(16, 16), 0), "steelhelmet", Translate::SteelHelmet, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::SteelArmor), getTeamIcon("steelarmor", "SteelArmor.png", team_num, Vec2f(16, 16), 0), "steelarmor", Translate::SteelArmor, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 3);
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Spear), getTeamIcon("spear", "Spear.png", team_num, Vec2f(42, 7), 0), "spear", Translate::Spear, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 60);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Backpack), getTeamIcon("backpack", "Backpack.png", team_num, Vec2f(16, 16), 0), "backpack", Translate::Backpack, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 15);
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
	}
	{
		ShopItem@ s = addShopItem(this, name(Translate::Parachutepack), getTeamIcon("parachutepack", "Parachutepack.png", team_num, Vec2f(16, 16), 0), "parachutepack", Translate::Parachutepack, false);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
	}
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
