//Gingerbeard @ November 17, 2024

#include "EmotesCommon.as";
#include "ParticleTeleport.as";
#include "Zombie_Translation.as";
#include "TraderShopCommon.as";
#include "Requirements.as";

const u8 stay_minutes = 4;

void onInit(CBlob@ this)
{
	this.getBrain().server_SetActive(true);
	
	this.sendonlyvisible = false;
	
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	addOnShopMadeItem(this, @onShopMadeItem);
	
	Random seed(this.getNetworkID());

	Shop shop(this, getTranslatedString("Buy")+"!!!");
	shop.menu_size = Vec2f(7, 4);
	shop.button_enable_radius = 35.0f;
	
	{
		SaleItem s(shop.items, name(Translate::ScrollFowl), "$scroll_fowl$", "fowl", name(Translate::ScrollFowl), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 20);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollRoyalty), "$scroll_royalty$", "royalty", name(Translate::ScrollRoyalty), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 40);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollWisent), "$scroll_wisent$", "wisent", name(Translate::ScrollWisent), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollFish), "$scroll_fish$", "fish", name(Translate::ScrollFish), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(shop.items, getTranslatedString("Scroll of Drought"), "$scroll_drought$", "drought", getTranslatedString("Scroll of Drought"), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 30);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollFlora), "$scroll_flora$", "flora", name(Translate::ScrollFlora), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollRevive), "$scroll_revive$", "revive", name(Translate::ScrollRevive), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	/*{
		SaleItem s(shop.items, name(Translate::ScrollCrate), "$scroll_crate$", "crate", name(Translate::ScrollCrate), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}*/
	/*{
		SaleItem s(shop.items, name(Translate::ScrollClone), "$scroll_clone$", "clone", name(Translate::ScrollClone), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 200);
	}*/
	{
		SaleItem s(shop.items, name(Translate::ScrollRepair), "$scroll_repair$", "repair", name(Translate::ScrollRepair), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollHealth), "$scroll_health$", "health", name(Translate::ScrollHealth), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
	}
	{
		SaleItem s(shop.items, getTranslatedString("Scroll of Carnage"), "$scroll_carnage$", "carnage", getTranslatedString("Scroll of Carnage"), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
	}
	{
		SaleItem s(shop.items, Translate::ScrollMidas, "$scroll_midas$", "midas", Translate::ScrollMidas, ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 150);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollTeleport), "$scroll_teleport$", "teleport", name(Translate::ScrollTeleport), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 20);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollSea), "$scroll_sea$", "sea", name(Translate::ScrollSea), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 200);
	}
	{
		SaleItem s(shop.items, name(Translate::ScrollStone), "$scroll_stone$", "stone", name(Translate::ScrollStone), ItemType::scroll, 1, 1);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		SaleItem s(shop.items, name(Translate::Musket), "$musket$", "musket", name(Translate::Musket));
		s.stock = 3 + seed.NextRanged(6);
		AddRequirement(s.requirements, "coin", "", "Coins", 349);
	}
	{
		SaleItem s(shop.items, name(Translate::MusketBalls), "$mat_musketballs$", "mat_musketballs", name(Translate::MusketBalls));
		s.stock = 40 + seed.NextRanged(15);
		AddRequirement(s.requirements, "coin", "", "Coins", 49);
	}
	{
		SaleItem s(shop.items, name(Translate::SteelHelmet), "$steelhelmet$", "steelhelmet", name(Translate::SteelHelmet));
		s.stock = 2 + seed.NextRanged(6);
		AddRequirement(s.requirements, "coin", "", "Coins", 149);
	}
	{
		SaleItem s(shop.items, name(Translate::SteelArmor), "$steelarmor$", "steelarmor", name(Translate::SteelArmor));
		s.stock = 2 + seed.NextRanged(5);
		AddRequirement(s.requirements, "coin", "", "Coins", 399);
	}
	{
		SaleItem s(shop.items, Translate::Bigbomb, "$bigbomb$", "bigbomb", Translate::Bigbomb);
		s.stock = 5 + seed.NextRanged(15);
		AddRequirement(s.requirements, "coin", "", "Coins", 69);
	}
	{
		SaleItem s(shop.items, name(Translate::HolyGrenade), "$holygrenade$", "holygrenade", desc(Translate::HolyGrenade));
		s.stock = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", 999);
	}
	{
		SaleItem s(shop.items, name(Translate::Cake), "$cake$", "cake", name(Translate::Cake));
		s.stock = 7 + seed.NextRanged(8);
		AddRequirement(s.requirements, "coin", "", "Coins", 99);
	}
	{
		SaleItem s(shop.items, name(Translate::Chainsaw), "$chainsaw$", "chainsaw", name(Translate::Chainsaw));
		s.stock = 2 + seed.NextRanged(3);
		AddRequirement(s.requirements, "coin", "", "Coins", 149);
	}
	{
		SaleItem s(shop.items, name(Translate::SteelDrill), "$steeldrill$", "steeldrill", name(Translate::SteelDrill));
		s.stock = 2 + seed.NextRanged(3);
		AddRequirement(s.requirements, "coin", "", "Coins", 199);
	}
	{
		SaleItem s(shop.items, name(Translate::Spear), "$spear$", "spear", name(Translate::Spear));
		s.stock = 3 + seed.NextRanged(5);
		AddRequirement(s.requirements, "coin", "", "Coins", 159);
	}

	this.set_u32("time till departure", getGameTime() + getTicksASecond() * 60 * stay_minutes);

	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	Chat(this, Translate::Tim4);

	ParticleTeleport(this.getPosition());
}

void onShopMadeItem(CBlob@ this, CBlob@ caller, CBlob@ blob, SaleItem@ item)
{
	this.getSprite().PlaySound("/ChaChing.ogg");
	
	if (blob !is null && blob.getName() == "holygrenade")
	{
		Chat(this, Translate::Tim2);
	}
}

void Chat(CBlob@ this, const string&in text)
{
	Sound::Play("ZombieGroan1.ogg", this.getPosition(), 1.0f, 1.2f);
	this.Chat(text);
}

void onTick(CBlob@ this)
{
	const u32 gameTime = getGameTime();
	
	if (this.getTickSinceCreated() == 120)
	{
		Chat(this, Translate::Tim3);
	}
	
	//trader looks at player when nearby
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null)
	{
		Vec2f pos = this.getPosition();
		Vec2f localPos = localBlob.getPosition();
		if ((localPos - pos).Length() < 70.0f && !getMap().rayCastSolid(pos, localPos))
		{
			this.SetFacingLeft(localPos.x < pos.x);
		}
	}

	const u32 timeTillLeave = this.get_u32("time till departure");
	if (timeTillLeave-30*30 == gameTime)
	{
		Chat(this, Translate::Tim0);
	}
	if (timeTillLeave-30 == gameTime)
	{
		Chat(this, Translate::Tim1);
	}
	if (timeTillLeave < gameTime)
	{
		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	ParticleTeleport(this.getPosition());
}
