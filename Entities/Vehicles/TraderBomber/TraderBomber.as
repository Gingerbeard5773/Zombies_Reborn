#include "Requirements_Trader.as";
#include "VehicleCommon.as";
#include "MakeScroll.as";
#include "Hitters.as";
#include "EmotesCommon.as";
#include "Zombie_Translation.as";
#include "ParticleTeleport.as";

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
	
	if (isServer())
	{
		//hack
		this.set_string("shop seed", XORRandom(5)+"-"+XORRandom(5)+"-"+XORRandom(4));
		this.Sync("shop seed", true);
	}
	
	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(3, 5));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);
	
	string[]@ seeds = this.get_string("shop seed").split("-");
	switch(parseInt(seeds[0]))
	{
		case 0:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Carnage", "$scroll_carnage$", "scroll_carnage", ZombieDesc::carnage_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
			AddStock(s, 1);
			break;
		}
		case 1:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Midas", "$scroll_midas$", "scroll_midas", ZombieDesc::midas_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
			AddStock(s, 1);
			break;
		}
		case 2:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Sea", "$scroll_sea$", "scroll_sea", ZombieDesc::sea_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
			AddStock(s, 1);
			break;
		}
		case 3:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Conveyance", "$scroll_teleport$", "scroll_teleport", ZombieDesc::teleport_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 20);
			AddStock(s, 2);
			break;
		}
		case 4:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Quarry", "$scroll_stone$", "scroll_stone", ZombieDesc::stone_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 30);
			AddStock(s, 1);
			break;
		}
	}
	switch(parseInt(seeds[1]))
	{
		case 0:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Ressurection", "$scroll_revive$", "scroll_revive", ZombieDesc::revive_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 30);
			AddStock(s, 1);
			break;
		}
		case 1:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Compaction", "$scroll_crate$", "scroll_crate", ZombieDesc::crate_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
			AddStock(s, 2);
			break;
		}
		case 2:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Duplication", "$scroll_clone$", "scroll_clone", ZombieDesc::clone_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
			AddStock(s, 1);
			break;
		}
		case 3:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Drought", "$scroll_drought$", "scroll_drought", ZombieDesc::drought_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 30);
			AddStock(s, 2);
			break;
		}
		case 4:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Harvest", "$scroll_flora$", "scroll_flora", ZombieDesc::flora_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
			AddStock(s, 2);
			break;
		}
	}
	switch(parseInt(seeds[2]))
	{
		case 0:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Royalty", "$scroll_royalty$", "scroll_royalty", ZombieDesc::royalty_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 40);
			AddStock(s, 3);
			break;
		}
		case 1:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Wisent", "$scroll_wisent$", "scroll_wisent", ZombieDesc::wisent_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
			AddStock(s, 1);
			break;
		}
		case 2:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Fowl", "$scroll_fowl$", "scroll_fowl", ZombieDesc::fowl_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
			AddStock(s, 1);
			break;
		}
		case 3:
		{
			ShopItem@ s = addShopItem(this, "Scroll of Fish", "$scroll_fish$", "scroll_fish", ZombieDesc::fish_desc, true);
			s.spawnNothing = true;
			AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
			AddStock(s, 1);
			break;
		}
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Gold (50)", "$mat_gold$", "mat_gold", "Buy 50 gold for 700 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 700);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Stone (250)", "$mat_stone$", "mat_stone", "Buy 250 Stone for 300 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Wood (250)", "$mat_wood$", "mat_wood", "Buy 250 Wood for 100 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Gold (50)", "$COIN$", "coin_600", "Sell 50 gold for 600 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Stone (250)", "$COIN$", "coin_200", "Sell 250 stone for 200 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Wood (250)", "$COIN$", "coin_35", "Sell 250 wood for 35 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Flour (50)", "$mat_flour$", "mat_flour", "Buy 50 Flour for 300 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Burger (1)", "$food$", "food", "Buy 1 Burger for 225 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 225);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Chicken (1)", "$chicken$", "chicken", "Buy 1 Chicken for 230 $COIN$", true);
		s.customData = 255;
		AddRequirement(s.requirements, "coin", "", "Coins", 230);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Flour (50)", "$COIN$", "coin_200", "Sell 50 flour for 200 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "mat_flour", "Flour", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Burger (1)", "$COIN$", "coin_200", "Sell 1 Burger for 125 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "food", "Burger", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Chicken (1)", "$COIN$", "coin_100", "Sell 1 Chicken for 100 $COIN$", true);
		s.spawnNothing = true;
		s.customData = 255;
		AddRequirement(s.requirements, "blob", "chicken", "Chicken", 1);
	}
	
	//VEHICLE
	Vehicle_Setup(this, 47.0f, 0.19f, Vec2f(0.0f, 0.0f), false);
	
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	
	Vehicle_SetupAirship(this, v, -350.0f);
	v.fly_amount = down_speed;
	
	this.set_u32("time till departure", getGameTime() + getTicksASecond() * 60 * stay_minutes);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	//this.getShape().SetOffset(Vec2f(0,0));
	//this.getShape().getConsts().bullet = true;
	//this.getShape().getConsts().transports = true;
}

// SHOP

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	//this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
		
		u16 caller_netid, item;
		if (!params.saferead_netid(caller_netid) || !params.saferead_netid(item))
			return;

		const string name = params.read_string();
		const u8 s_index = params.read_u8();
		
		ShopItem[]@ shop_items;
		if (!this.get(SHOP_ARRAY, @shop_items)) return;
		
		if (s_index >= shop_items.length) return;
		ShopItem@ s = shop_items[s_index];
		if (isClient())
		{
			s.customData = s.customData == 255 ? 255 : Maths::Max(s.customData - 1, 0);
		}
		
		CBlob@ caller = getBlobByNetworkID(caller_netid);

		if (isServer())
		{
			string[] spl = name.split("_");
			if (name.findFirst("scroll") != -1)
			{
				CBlob@ scroll = server_MakePredefinedScroll(this.getPosition(), spl[1]);
				if (scroll !is null)
				{
					if (caller !is null && !caller.server_PutInInventory(scroll))
					{
						scroll.setPosition(caller.getPosition());
					}
				}
			}
			else if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = caller.getPlayer();
				if (callerPlayer is null) return;

				callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}
		}
	}
}

// GENERIC & VEHICLE

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	const u32 gameTime = getGameTime();
	const u32 timeTillLeave = this.get_u32("time till departure");
	if (timeTillLeave+30*15 < gameTime)
	{
		this.server_Die();
	}
	
	v.fly_amount = timeTillLeave < gameTime ? up_speed : down_speed;
	
	this.AddForce(Vec2f(0, v.fly_speed * v.fly_amount));
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((customData == Hitters::bite || customData == Hitters::keg) && this.get_u32("time till departure") > getGameTime())
	{
		set_emote(this, Emotes::frown, getTicksASecond()*5);
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

	CSpriteLayer@ balloon = this.addSpriteLayer("balloon", "TraderBalloon.png", 48, 72, XORRandom(8), 0);
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
		CSpriteLayer@ flag = this.addSpriteLayer("flag", "Ballista.png", 32, 32, XORRandom(8), 0);
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
