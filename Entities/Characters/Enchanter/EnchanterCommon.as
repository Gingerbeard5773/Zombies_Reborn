// Enchanter Common

#include "RequirementsCustom.as"
#include "Zombie_Translation.as"
#include "MakeScroll.as"

void SetupEnchants(CBlob@ this)
{
	dictionary enchants;

	enchants.set("musket",           Enchant("shotgun",             Translate("Shotgun")));
	enchants.set("crossbow",         Enchant("magicquiver",         Translate("MagicQuiver")));
	enchants.set("spear",            Enchant("trident",             Translate("Trident")));
	enchants.set("steelhelmet",      Enchant("goldenhelmet",        Translate("GoldenHelmet")));
	enchants.set("steelarmor",       Enchant("goldenarmor",         Translate("GoldenArmor")));
	enchants.set("headlamp",         Enchant("crowntelepathy",      Translate("CrownTelepathy")));
	enchants.set("parachutepack",    Enchant("wings",               Translate("Wings")));
	enchants.set("chicken",          Enchant("goldenchicken",       Translate("GoldenChicken")));
	enchants.set("keg",              Enchant("holygrenade",         Translate("HolyGrenade")));
	enchants.set("scroll_fish",      Enchant("scroll_sea",          Translate("ScrollSea")));
	enchants.set("scroll_revive",    Enchant("scroll_resurgence",   Translate("ScrollResurgence")));
	enchants.set("scroll_teleport",  Enchant("scroll_time",         Translate("ScrollTime")));
	enchants.set("scroll_drought",   Enchant("scroll_desiccation",  Translate("ScrollDesiccation")));
	enchants.set("scroll_carnage",   Enchant("scroll_obliteration", Translate("ScrollObliteration")));
	enchants.set("scroll_stone",     Enchant("scroll_iron",         Translate("ScrollIron")));
	enchants.set("scroll_midas",     Enchant("scroll_gilding",      Translate("ScrollGilding")));
	enchants.set("scroll_royalty",   Enchant("scroll_rewind",       Translate("ScrollRewind")));

	this.set("enchants", enchants);
}

Payment@[]@ getEnchanterPayments()
{
	Payment@[] payments = {

	//Payment("coin",           "Coins",           50, 500,   70),

	Payment("mat_gold",       "Gold",            50, 150,   100),
	Payment("mat_steelingot", "Steel Ingot",     3, 8,      40),
	Payment("mat_ironingot",  "Iron Ingot",      8, 32,     40),
	Payment("mat_coal",       "Coal",            150, 400,  40),

	Payment("scroll",         "Scroll",          1, 1,      70),

	Payment("bread",          "Bread",           1, 3,      10),
	Payment("cake",           "Cake",            1, 1,      10),
	Payment("cookedchicken",  "Cooked Chicken",  1, 1,      10),
	Payment("cookedfish",     "Cooked Fish",     1, 1,      10),
	Payment("cookedsteak",    "Cooked Steak",    1, 1,      10),
	Payment("food",           "Burger",          1, 1,      10),
	Payment("beer",           "Beer",            1, 3,      10),

	Payment("crossbow",       "Crossbow",        1, 3,      10),
	Payment("scythe",         "Scythe",          1, 2,      10),
	Payment("chainsaw",       "Chainsaw",        1, 2,      10),
	Payment("musket",         "Musket",          1, 2,      10),
	Payment("steeldrill",     "Steel Drill",     1, 2,      10),
	Payment("spear",          "Spear",           1, 2,      10),
	Payment("partisan",       "Partisan",        1, 1,      10),

	Payment("steelhelmet",    "Steel Helmet",    1, 2,      10),
	Payment("steelarmor",     "Steel Armor",     1, 2,      10),
	Payment("scubagear",      "Scuba Gear",      1, 2,      10),
	Payment("headlamp",       "Head Lamp",       1, 2,      10),
	Payment("backpack",       "Backpack",        1, 2,      10),
	Payment("parachutepack",  "Parachute Pack",  1, 2,      10),

	Payment("keg",            "Keg",             1, 2,      10),
	Payment("molotov",        "Molotov",         1, 4,      10),
	Payment("bigbomb",        "Big Bomb",        1, 2,      10),

	Payment("builder",        "Builder",         1, 1,      10),
	Payment("knight",         "Knight",          1, 1,      10),
	Payment("archer",         "Archer",          1, 1,      10),

	Payment("zombie",         "Zombie",          1, 1,      10),
	Payment("zombieknight",   "Zombie Knight",   1, 1,      10),
	Payment("horror",         "Horror",          1, 1,      10, true),

	Payment("shotgun",        "Shotgun",         1, 1,      10, true),
	Payment("bazooka",        "Bazooka",         1, 1,      10, true),
	Payment("flamethrower",   "Flamethrower",    1, 1,      10, true)

	};

	return @payments;
}


/// Enchant

class Enchant
{
	string result, description;
	Enchant(string result, string description)
	{
		this.result = result;
		this.description = description;
	}
}

Enchant@ getEnchant(CBlob@ this, CBlob@ item)
{
	dictionary@ enchants;
	if (!this.get("enchants", @enchants)) return null;

	Enchant@ enchant;
	enchants.get(getEnchantKey(item), @enchant);
	return enchant;
}

bool isEnchantable(CBlob@ this, CBlob@ item)
{
	dictionary@ enchants;
	if (!this.get("enchants", @enchants)) return false;

	return enchants.exists(getEnchantKey(item));
}

string getEnchantKey(CBlob@ item)
{
	if (item.exists("scroll defname0")) 
	{
		return "scroll_" + item.get_string("scroll defname0");
	}
	/*else if (item.exists("seed_grow_blobname")) 
	{
		return "seed_" + item.get_string("seed_grow_blobname");
	}*/

	return item.getName();
}

CBlob@ server_MakeEnchantedItem(CBlob@ this, CBlob@ item)
{
	Enchant@ enchant = getEnchant(this, item);
	if (enchant is null) return null;

	string[]@ tokens = enchant.result.split("_");
	if (tokens.length > 1)
	{
		if (tokens[0] == "scroll")
		{
			return server_MakePredefinedScroll(item.getPosition(), tokens[1]);
		}
		/*else if (tokens[0] == "seed")
		{
			
		}*/
	}

	return server_CreateBlob(enchant.result, item.getTeamNum(), item.getPosition());
}


/// Payment

class Payment
{
	string item_name, description;
	int minimum, maximum, weight;
	bool must_exist;
	Payment(string item_name, string description, int minimum, int maximum, int weight, bool must_exist = false)
	{
		this.item_name = item_name;
		this.description = getTranslatedString(description);
		this.minimum = minimum;
		this.maximum = maximum;
		this.weight = weight;
		this.must_exist = must_exist;
	}
}

void SetupPayment(CBitStream@ reqs, const u8&in enchants_count, Random@ seed)
{
	Payment@[]@ payments = getEnchanterPayments();

	u32 weights_sum = 0;
	for (u8 i = 0; i < payments.length; i++)
	{
		weights_sum += payments[i].weight;
	}

	Payment@[] items;
	//const u8 items_count = Maths::Max(enchants_count, 1 + seed.NextRanged(3));
	const u8 items_count = enchants_count + seed.NextRanged(3);
	for (u8 a = 0; a < items_count; a++)
	{
		Payment@ item = GetRandomPayment(payments, weights_sum, seed);
		if (item.must_exist && getBlobByName(item.item_name) is null)
		{
			a--;
			continue;
		}

		bool exists = false;
		for (u8 i = 0; i < items.length; i++)
		{
			if (items[i].item_name == item.item_name)
			{
				exists = true;
				a--;
			}
		}
		if (!exists) items.push_back(item);
	}
	
	for (u8 i = 0; i < items.length; i++)
	{
		Payment@ item = items[i];
		const u32 range = item.maximum - item.minimum + 1;
		//const u32 ratio = Maths::Round(range / Maths::Min(max_enchants, range) + 0.01f);
		//const u32 skew = ratio * (enchants_count - 1);
		//const u32 extra = seed.NextRanged(range + skew);
		const u32 extra = seed.NextRanged(range);
		const u32 amount = item.minimum + Maths::Min(extra, range - 1);
		const string type = item.item_name == "coin" ? "coin" : "blob";
		AddRequirement(reqs, type, item.item_name, item.description, amount);
	}
}

Payment@ GetRandomPayment(Payment@[]@ payments, const u32&in weights_sum, Random@ seed)
{
	const u32 random_weight = seed.NextRanged(weights_sum);
	u32 current_number = 0;

	for (u8 i = 0; i < payments.length; i++)
	{
		Payment@ item = payments[i];
		if (random_weight <= current_number + item.weight)
		{
			return item;
		}

		current_number += item.weight;
	}

	return null;
}
