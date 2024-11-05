// Vehicle Workshop

#include "Requirements.as"
#include "Requirements_Tech.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "TeamIconToken.as"
#include "Zombie_Translation.as"

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);
	
	ShopMadeItem@ onMadeItem = @onShopMadeItem;
	this.set("onShopMadeItem handle", @onMadeItem);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	
	this.getCurrentScript().tickFrequency = 90;

	//INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(9, 4));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	const u8 team_num = this.getTeamNum();

	{
		const string bomber_icon = getTeamIcon("bomber", "Icon_Bomber.png", team_num, Vec2f(44, 74), 0);
		ShopItem@ s = addShopItem(this, "Bomber", bomber_icon, "bomber", Translate::Bomber, false, true);
		s.crate_icon = 7;
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
	}
	{
		const string bomber_icon = getTeamIcon("armoredbomber", "Icon_ArmoredBomber.png", team_num, Vec2f(44, 74), 0);
		ShopItem@ s = addShopItem(this, name(Translate::Armoredbomber), bomber_icon, "armoredbomber", desc(Translate::Armoredbomber), false, true);
		s.crate_icon = 7;
		AddRequirement(s.requirements, "coin", "", "Coins", 200);
		AddRequirement(s.requirements, "blob", "mat_steelingot", name(Translate::SteelIngot), 4);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
	}
	{
		const string cata_icon = getTeamIcon("catapult", "VehicleIcons.png", team_num, Vec2f(32, 32), 0);
		ShopItem@ s = addShopItem(this, "Catapult", cata_icon, "catapult", cata_icon + "\n\n\n" + Descriptions::catapult, false, true);
		s.crate_icon = 4;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::catapult);
	}
	{
		const string ballista_icon = getTeamIcon("ballista", "VehicleIcons.png", team_num, Vec2f(32, 32), 1);
		ShopItem@ s = addShopItem(this, "Ballista", ballista_icon, "ballista", ballista_icon + "\n\n\n" + Descriptions::ballista, false, true);
		s.crate_icon = 5;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::ballista);
	}
	{
		const string bomber_icon = getTeamIcon("tank", "Icon_tank.png", team_num, Vec2f(55, 32), 0);
		ShopItem@ s = addShopItem(this, name(Translate::Tank), bomber_icon, "tank", desc(Translate::Tank), false, true);
		s.crate_icon = 11;
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 300);
	}
	{
		const string bow_icon = getTeamIcon("mounted_bow", "MountedBow.png", team_num, Vec2f(16, 16), 6);
		ShopItem@ s = addShopItem(this, "Mounted Bow", bow_icon, "mounted_bow", Translate::Mountedbow, false, true);
		s.crate_icon = 6;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "coin", "", "Coins", 85);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	}
	{
		ShopItem@ s = addShopItem(this, "Ballista Ammo", "$mat_bolts$", "mat_bolts", "$mat_bolts$\n\n\n" + Descriptions::ballista_ammo, false, false);
		s.crate_icon = 5;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::ballista_ammo);
	}
	{
		ShopItem@ s = addShopItem(this, "Ballista Shells", "$mat_bomb_bolts$", "mat_bomb_bolts", "$mat_bomb_bolts$\n\n\n" + Descriptions::ballista_bomb_ammo, false, false);
		s.crate_icon = 5;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::ballista_bomb_ammo);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onShopMadeItem(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id, caller_id, item_id;
	string name;

	if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
	{
		return;
	}

	CBlob@ caller = getBlobByNetworkID(caller_id);
	if (caller is null) return;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	
	//heal overlapping vehicles
	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return;

	for (u16 i = 0; i < overlapping.length; ++i)
	{
		CBlob@ blob = overlapping[i];
		const f32 initialHealth = blob.getInitialHealth();
		if (blob.hasTag("vehicle") && blob.getHealth() < initialHealth)
		{
			blob.server_SetHealth(Maths::Min(blob.getHealth() + initialHealth / 15, initialHealth));
		}
	}
}
