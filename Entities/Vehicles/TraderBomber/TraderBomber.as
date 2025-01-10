#include "VehicleCommon.as";
#include "Hitters.as";
#include "EmotesCommon.as";
#include "ParticleTeleport.as";
#include "Zombie_Translation.as";
#include "TraderShopCommon.as";
#include "Requirements.as";

const u8 stay_minutes = 2;
const f32 up_speed = 1.0f;
const f32 down_speed = 0.75f;
bool said_hello = false;

// Trader Bomber

void onInit(CBlob@ this)
{
	said_hello = false;
	this.chatBubbleOffset = Vec2f(0, 48);
	this.SetChatBubbleFont("menu");
	
	this.SetMapEdgeFlags(u8(CBlob::map_collide_sides));
	
	this.SetMinimapOutsideBehaviour(CBlob::minimap_none);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);
	
	this.sendonlyvisible = false;
	
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	addOnShopMadeItem(this, @onShopMadeItem);

	AddIconToken("$tree_pine$",  "Trees.png", Vec2f(16, 16), 20);
	AddIconToken("$tree_bushy$", "Trees.png", Vec2f(16, 16), 4);

	Random seed(this.getNetworkID());

	Shop shop(this, "Trader");
	shop.menu_size = Vec2f(3, 6);

	AddRandomItemsToShop(shop, seed, 3);
	
	{
		SaleItem s(shop.items, buy("Gold", 50), "$mat_gold$", "mat_gold", buy2("Gold", 50, 700), ItemType::material, 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 700);
	}
	{
		SaleItem s(shop.items, buy("Stone", 250), "$mat_stone$", "mat_stone", buy2("Stone", 250, 300), ItemType::material, 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		SaleItem s(shop.items, buy("Wood", 250), "$mat_wood$", "mat_wood", buy2("Wood", 250, 100), ItemType::material, 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	}
	{
		SaleItem s(shop.items, sell("Gold", 50), "$COIN$", "coin", sell2("Gold", 50, 600), ItemType::coin, 600);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		SaleItem s(shop.items, sell("Stone", 250), "$COIN$", "coin", sell2("Stone", 250, 200), ItemType::coin, 200);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
	}
	{
		SaleItem s(shop.items, sell("Wood", 250), "$COIN$", "coin", sell2("Wood", 250, 50), ItemType::coin, 50);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
	}
	{
		SaleItem s(shop.items, buy(Translate::Flour, 50), "$mat_flour$", "mat_flour", buy2(Translate::Flour, 50, 300), ItemType::material, 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		SaleItem s(shop.items, buy("Steak", 1), "$steak$", "steak", buy2("Steak", 1, 230));
		AddRequirement(s.requirements, "coin", "", "Coins", 230);
	}
	{
		SaleItem s(shop.items, buy("Egg", 1), "$egg$", "egg", buy2("Egg", 1, 150));
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
	}
	{
		SaleItem s(shop.items, sell(Translate::Flour, 50), "$COIN$", "coin", sell2(Translate::Flour, 50, 200), ItemType::coin, 200);
		AddRequirement(s.requirements, "blob", "mat_flour", "Flour", 50);
	}
	{
		SaleItem s(shop.items, sell("Burger", 1), "$COIN$", "coin", sell2("Burger", 1, 250), ItemType::coin, 250);
		AddRequirement(s.requirements, "blob", "food", "Burger", 1);
	}
	{
		SaleItem s(shop.items, sell("Chicken", 1), "$COIN$", "coin", sell2("Chicken", 1, 100), ItemType::coin, 100);
		AddRequirement(s.requirements, "blob", "chicken", "Chicken", 1);
	}
	{
		SaleItem s(shop.items, buy("Bushy Tree", 1), "$tree_bushy$", "tree_bushy", buy2("Bushy Tree", 1, 400), ItemType::seed);
		AddRequirement(s.requirements, "coin", "", "Coins", 400);
	}
	{
		SaleItem s(shop.items, buy(Translate::IronOre, 250), "$mat_iron_icon$", "mat_iron", buy2(Translate::IronOre, 250, 1400), ItemType::material, 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 1400);
	}
	{
		SaleItem s(shop.items, buy(name(Translate::Coal), 250), "$mat_coal_icon$", "mat_coal", buy2(name(Translate::Coal), 250, 500), ItemType::material, 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
	}
	
	//VEHICLE
	Vehicle_Setup(this, 47.0f, 0.19f, Vec2f_zero, false);
	
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	
	Vehicle_SetupAirship(this, v, -350.0f);
	v.fly_amount = down_speed;
	
	this.set_u32("time till departure", getGameTime() + getTicksASecond() * 60 * stay_minutes);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
}

string buy(const string&in item, const u16&in quantity)
{
	return Translate::Buy.replace("{ITEM}", getTranslatedString(item)).replace("{QUANTITY}", quantity+"");
}

string buy2(const string&in item, const u16&in quantity, const u16&in coins)
{
	return Translate::Buy2.replace("{ITEM}", getTranslatedString(item)).replace("{QUANTITY}", quantity+"").replace("{COINS}", coins+"");
}

string sell(const string&in item, const u16&in quantity)
{
	return Translate::Sell.replace("{ITEM}", getTranslatedString(item)).replace("{QUANTITY}", quantity+"");
}

string sell2(const string&in item, const u16&in quantity, const u16&in coins)
{
	return Translate::Sell2.replace("{ITEM}", getTranslatedString(item)).replace("{QUANTITY}", quantity+"").replace("{COINS}", coins+"");
}

void AddRandomItemsToShop(Shop@ shop, Random@ seed, const u8&in amount)
{
	SaleItem@[] items;
	{
		SaleItem s(items, name(Translate::ScrollFowl), "$scroll_fowl$", "fowl", Translate::TradeScrollFowl, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 20);
	}
	{
		SaleItem s(items, name(Translate::ScrollRoyalty), "$scroll_royalty$", "royalty", Translate::TradeScrollRoyalty, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 40);
	}
	{
		SaleItem s(items, name(Translate::ScrollWisent), "$scroll_wisent$", "wisent", Translate::TradeScrollWisent, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(items, name(Translate::ScrollFish), "$scroll_fish$", "fish", Translate::TradeScrollFish, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(items, getTranslatedString("Scroll of Drought"), "$scroll_drought$", "drought", Translate::TradeScrollDrought, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 30);
	}
	{
		SaleItem s(items, name(Translate::ScrollFlora), "$scroll_flora$", "flora", Translate::TradeScrollFlora, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(items, name(Translate::ScrollRevive), "$scroll_revive$", "revive", Translate::TradeScrollRevive, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(items, name(Translate::ScrollCrate), "$scroll_crate$", "crate", Translate::TradeScrollCrate, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		SaleItem s(items, name(Translate::ScrollClone), "$scroll_clone$", "clone", Translate::TradeScrollDupe, ItemType::scroll, 1, 1);
		s.custom_data = 5;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 200);
	}
	{
		SaleItem s(items, name(Translate::ScrollRepair), "$scroll_repair$", "repair", Translate::TradeScrollRepair, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
	}
	{
		SaleItem s(items, name(Translate::ScrollHealth), "$scroll_health$", "health", Translate::TradeScrollHealth, ItemType::scroll, 1, 1);
		s.custom_data = 18;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
	}
	{
		SaleItem s(items, getTranslatedString("Scroll of Carnage"), "$scroll_carnage$", "carnage", Translate::TradeScrollCarnage, ItemType::scroll, 1, 1);
		s.custom_data = 15;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
	}
	{
		SaleItem s(items, Translate::ScrollMidas, "$scroll_midas$", "midas", Translate::TradeScrollMidas, ItemType::scroll, 1, 1);
		s.custom_data = 15;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
	}
	{
		SaleItem s(items, name(Translate::ScrollTeleport), "$scroll_teleport$", "teleport", Translate::TradeScrollTeleport, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 20);
	}
	{
		SaleItem s(items, name(Translate::ScrollSea), "$scroll_sea$", "sea", Translate::TradeScrollSea, ItemType::scroll, 1, 1);
		s.custom_data = 2;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 200);
	}
	{
		SaleItem s(items, name(Translate::ScrollStone), "$scroll_stone$", "stone", Translate::TradeScrollStone, ItemType::scroll, 1, 1);
		s.custom_data = 20;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	
	u32 weights_sum = 0;
	for (u8 i = 0; i < items.length; i++)
	{
		weights_sum += items[i].custom_data;
	}
	
	for (u8 a = 0; a < amount; a++)
	{
		SaleItem@ add_item = GetRandomSaleItem(items, weights_sum, seed);
		bool exists = false;
		for (u8 i = 0; i < shop.items.length; i++)
		{
			SaleItem@ item = shop.items[i];
			if (item.blob_name == add_item.blob_name)
			{
				exists = true;
				a--;
			}
		}
		if (!exists) shop.items.push_back(add_item);
	}
}

SaleItem@ GetRandomSaleItem(SaleItem@[]@ items, const u32&in weights_sum, Random@ seed)
{
	const u32 random_weight = seed.NextRanged(weights_sum);
	u32 current_number = 0;

	for (u8 i = 0; i < items.length; i++)
	{
		SaleItem@ item = items[i];
		if (random_weight <= current_number + item.custom_data)
		{
			return item;
		}

		current_number += item.custom_data;
	}

	return null;
}

void onShopMadeItem(CBlob@ this, CBlob@ caller, CBlob@ blob, SaleItem@ item)
{
	this.getSprite().PlaySound("/ChaChing.ogg");
}

// GENERIC & VEHICLE

void onTick(CBlob@ this)
{
	const u32 gameTime = getGameTime();
	const u32 timeTillLeave = this.get_u32("time till departure");
	
	if (gameTime == timeTillLeave - 30 * 25)
	{
		const string[] messages = { Translate::TraderLeave0, Translate::TraderLeave1, Translate::TraderLeave2 };
		const string message = messages[XORRandom(messages.length)];
		this.Chat(message);
		Sound::Play("MigrantSayFriend.ogg", this.getPosition());
	}

	if (timeTillLeave+30*15 < gameTime)
	{
		this.server_Die();
	}

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	v.fly_amount = timeTillLeave < gameTime ? up_speed : down_speed;

	this.AddForce(Vec2f(0, v.fly_speed * v.fly_amount));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((customData == Hitters::bite || customData == Hitters::keg) && this.get_u32("time till departure") > getGameTime())
	{
		set_emote(this, "frown", getTicksASecond()*5);
		this.set_u32("time till departure", getGameTime());
	}
	
	return 0; //invincible
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		Vec2f pos = this.getPosition();
		if (pos.y > 0)
		{
			ParticleTeleport(pos);
		}
	}
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50.0f);
	this.getCurrentScript().tickFrequency = 5;
	
	// add balloon

	CSpriteLayer@ balloon = this.addSpriteLayer("balloon", "TraderBalloon.png", 48, 72);
	if (balloon !is null)
	{
		balloon.addAnimation("default", 0, false);
		int[] frames = { 0 };
		balloon.animation.AddFrames(frames);
		balloon.SetRelativeZ(1.0f);
		balloon.SetOffset(Vec2f(0.0f, -21.0f));
	}
	
	CSpriteLayer@ trader = this.addSpriteLayer("trader", "TraderMale.png", 16, 16);
	if (trader !is null)
	{
		trader.addAnimation("default", 100, true);
		int[] frames = { 0, 1, 3 };
		trader.animation.AddFrames(frames);
		trader.SetRelativeZ(-4.0f);
		trader.SetOffset(Vec2f(0.0f, 0.0f));
	}

	CSpriteLayer@ background = this.addSpriteLayer("background", "TraderBalloon.png", 24, 16);
	if (background !is null)
	{
		background.addAnimation("default", 0, false);
		background.animation.AddFrame(XORRandom(2)+3);
		background.SetRelativeZ(-5.0f);
		background.SetOffset(Vec2f(0.0f, -5.0f));
	}
	
	CSpriteLayer@ sign = this.addSpriteLayer("sign", "TraderBalloon.png", 32, 16);
	if (sign !is null)
	{
		sign.addAnimation("default", 0, false);
		int[] frames = { 7 };
		sign.animation.AddFrames(frames);
		sign.SetRelativeZ(2.0f);
		sign.SetOffset(Vec2f(0.0f, -7.0f));
	}
	
	CSpriteLayer@ goods = this.addSpriteLayer("goods", "TraderBalloon.png", 16, 16, XORRandom(8), 0);
	if (goods !is null)
	{
		goods.addAnimation("default", 0, false);
		const u8 interval = XORRandom(3) * 8 + 27;
		goods.animation.AddFrame(XORRandom(5) + interval);
		goods.SetRelativeZ(2.0f);
		goods.SetOffset(Vec2f(5.0f, 7.0f));
	}
	CSpriteLayer@ goods1 = this.addSpriteLayer("goods1", "TraderBalloon.png", 16, 16, XORRandom(8), 0);
	if (goods1 !is null)
	{
		goods1.addAnimation("default", 0, false);
		const u8 interval = XORRandom(3) * 8 + 27;
		goods1.animation.AddFrame(XORRandom(5) + interval);
		goods1.SetRelativeZ(2.0f);
		goods1.SetOffset(Vec2f(-5.0f, 7.0f));
	}
	if (XORRandom(2) == 0)
	{
		CSpriteLayer@ goods2 = this.addSpriteLayer("goods2", "TraderBalloon.png", 7, 26, XORRandom(8), 0);
		if (goods2 !is null)
		{
			goods2.addAnimation("default", 0, false);
			goods2.animation.AddFrame(XORRandom(3) + 7);
			goods2.SetRelativeZ(2.0f);
			goods2.SetOffset(Vec2f(14.0f, -15.0f));
		}
	}
	else if (XORRandom(3) == 0)
	{
		CSpriteLayer@ flag = this.addSpriteLayer("flag", "Entities/Vehicles/Ballista/Ballista.png", 32, 32, XORRandom(8), 0);
		if (flag !is null)
		{
			flag.addAnimation("default", 3, true);
			int[] frames = { 15, 14, 13 };
			flag.animation.AddFrames(frames);
			flag.SetRelativeZ(1.5f);
			flag.SetOffset(Vec2f(20.0f, -28.0f));
		}
	}

	CSpriteLayer@ burner = this.addSpriteLayer("burner", "Balloon.png", 8, 16);
	if (burner !is null)
	{
		{
			Animation@ a = burner.addAnimation("default", 3, true);
			int[] frames = { 41, 42, 43 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("up", 3, true);
			int[] frames = { 38, 39, 40 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("down", 3, true);
			int[] frames = { 44, 45, 44, 46 };
			a.AddFrames(frames);
		}
		burner.SetRelativeZ(1.5f);
		burner.SetOffset(Vec2f(0.0f, -26.0f));
	}
	
	if (XORRandom(2) == 0)
	{
		CSpriteLayer@ lantern = this.addSpriteLayer("lantern", "Lantern.png", 8, 8);
		if (lantern !is null)
		{
			lantern.addAnimation("default", 4, true);
			int[] frames = { 0, 1, 2 };
			lantern.animation.AddFrames(frames);
			lantern.SetRelativeZ(2.0f);
			lantern.SetOffset(Vec2f(-17.0f, -7.0f));
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	
	CSpriteLayer@ trader = this.getSpriteLayer("trader");
	if (trader !is null)
	{
		//trader looks at player when nearby
		CBlob@ localBlob = getLocalPlayerBlob();
		if (localBlob !is null)
		{
			Vec2f pos = blob.getPosition();
			Vec2f localPos = localBlob.getPosition();
			if ((localPos - pos).Length() < 70.0f && !getMap().rayCastSolid(pos, localPos))
			{
				trader.SetFacingLeft(localPos.x < pos.x);
				if (!said_hello)
				{
					Sound::Play("MigrantSayHello.ogg", pos);
					said_hello = true;
				}
			}
		}
	}

	CSpriteLayer@ burner = this.getSpriteLayer("burner");
	if (burner !is null)
	{
		burner.SetOffset(Vec2f(0.0f, -14.0f));
		s8 dir = blob.get_s8("move_direction");
		if (dir == 0)
		{
			blob.SetLightColor(SColor(255, 255, 240, 171));
			burner.SetAnimation("default");
		}
		else if (dir < 0)
		{
			blob.SetLightColor(SColor(255, 255, 240, 200));
			burner.SetAnimation("up");
		}
		else if (dir > 0)
		{
			blob.SetLightColor(SColor(255, 255, 200, 171));
			burner.SetAnimation("down");
		}
	}
}
