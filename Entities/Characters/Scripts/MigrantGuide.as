// Migrant Guide

// Gingerbeard @ June 21, 2025

string[]@ getGuideInfo()
{
	string[] infos =
	{
		Translate("Guide1"),
		Translate("Guide2"),
		Translate("Guide3"),
		Translate("Guide4"),
		Translate("Guide5"),
		Translate("Guide6"),
		Translate("Guide7"), 
		Translate("Guide8"),
		Translate("Guide9"),
		Translate("Guide10"),
		Translate("Guide11"),
		Translate("Guide12"),
		Translate("Guide13"), 
		Translate("Guide14"),
		Translate("Guide15"),
		Translate("Guide16"),
		Translate("Guide17"),
		Translate("Guide18"),
		Translate("Guide19")
	};

	return @infos;
}

dictionary@ getGuideItems()
{
	dictionary items;

	items.set("scroll_royalty",      Translate("GuideScrollRoyalty"));
	items.set("scroll_clone",        Translate("GuideScrollClone"));
	items.set("scroll_sea",          Translate("GuideScrollSea"));
	items.set("scroll_crate",        Translate("GuideScrollCrate"));
	items.set("scroll_revive",       Translate("GuideScrollRevive"));
	items.set("scroll_health",       Translate("GuideScrollHealth"));
	items.set("scroll_carnage",      Translate("GuideScrollCarnage"));
	items.set("scroll_teleport",     Translate("GuideScrollTeleport"));
	items.set("scroll_repair",       Translate("GuideScrollRepair"));
	items.set("scroll_midas",        Translate("GuideScrollMidas"));
	items.set("scroll_stone",        Translate("GuideScrollStone"));
	items.set("scroll_desiccation",  Translate("GuideScrollDesiccation"));
	items.set("scroll_resurgence",   Translate("GuideScrollResurgence"));
	items.set("scroll_time",         Translate("GuideScrollTime"));
	items.set("scroll_obliteration", Translate("GuideScrollObliteration"));
	items.set("scroll_iron",         Translate("GuideScrollIron"));
	items.set("scroll_gilding",      Translate("GuideScrollGilding"));
	items.set("scroll_rewind",       Translate("GuideScrollRewind"));

	items.set("holygrenade",         Translate("GuideHolyGrenade"));
	items.set("shotgun",             Translate("GuideShotgun"));
	items.set("bazooka",             Translate("GuideBazooka"));
	items.set("flamethrower",        Translate("GuideFlamethrower"));
	items.set("magicquiver",         Translate("GuideMagicQuiver"));
	items.set("trident",             Translate("GuideTrident"));
	items.set("goldenhelmet",        Translate("GuideGoldenHelmet"));
	items.set("goldenarmor",         Translate("GuideGoldenArmor"));
	items.set("crowntelepathy",      Translate("GuideCrownTelepathy"));
	items.set("wings",               Translate("GuideWings"));
	items.set("goldenchicken",       Translate("GuideGoldenChicken"));

	return @items;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.hasTag("migrant")) return;

	CRules@ rules = getRules();
	if (this.getNetworkID() != rules.get_netid("guide netid")) return;

	if (this.getNetworkID() == rules.get_netid("inventory access")) return;

	caller.CreateGenericButton(14, Vec2f(0, 0), this, Callback_AskQuestion, Translate("Help"));
}

void Callback_AskQuestion(CBlob@ this, CBlob@ caller)
{
	this.Chat(getRelevantGuideInfo(caller));
}

string getRelevantGuideInfo(CBlob@ caller)
{
	string[]@ possible = getGuideInfo();

	dictionary@ items = getGuideItems();

	CRules@ rules = getRules();

	// Information about the library
	CBlob@ library = getBlobByName("library");
	const string library_tip = library is null ? Translate("GuideRelevant1") : Translate("GuideRelevant2");
	possible.push_back(library_tip);

	// Information about sedgwick
	CBlob@ sedgwick = getBlobByName("sedgwick");
	if (sedgwick !is null)
	{
		addRelevantInfo(Translate("GuideRelevant3"), @possible, 10);
	}

	// Information about zombie portals
	CBlob@ portal = getBlobByName("zombieportal");
	if (portal !is null)
	{
		const string portal_tip = portal.hasTag("portal_activated") ? Translate("GuideRelevant7") : Translate("GuideRelevant6");
		addRelevantInfo(portal_tip, @possible, 10);
	}

	// Information about bobert
	CBlob@ bobert = getBlobByName("bobert");
	if (bobert !is null)
	{
		addRelevantInfo(Translate("GuideRelevant5"), @possible, 10);
	}
	else if (rules.get_u16("bobert_day") - rules.get_u16("day_number") < 4)
	{
		addRelevantInfo(Translate("GuideRelevant4"), @possible, 3);
	}

	// Information about the enchanter
	CBlob@ enchanter = getBlobByName("enchanter");
	if (enchanter !is null)
	{
		addRelevantInfo(Translate("GuideRelevant8"), @possible, 10);
	}

	// Information about items in our inventory
	CInventory@ inv = caller.getInventory();
	if (inv !is null)
	{
		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			const string description = getGuideInfoFromItem(items, item);
			if (description.isEmpty()) continue;

			addRelevantInfo(description, @possible, 10);
		}
	}

	// Information about our carried item.
	// If the item has a description, it takes priority over everything
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null)
	{
		const string description = getGuideInfoFromItem(items, carried);
		if (!description.isEmpty())
		{
			possible = { description };
		}
	}

	return possible[XORRandom(possible.length)];
}

void addRelevantInfo(const string&in info, string[]@ possible, const int&in relevancy)
{
	for (int i = 0; i < relevancy; i++)
	{
		possible.push_back(info);
	}
}

string getGuideInfoFromItem(dictionary@ items, CBlob@ item)
{
	string name = item.getName();

	if (item.exists("scroll defname0"))
	{
		name = "scroll_"+item.get_string("scroll defname0");
	}

	string description = "";
	if (items.exists(name))
	{
		items.get(name, description);
	}
	return description;
}
