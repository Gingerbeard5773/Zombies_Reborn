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

	items.set("clone",            Translate("GuideItem1"));
	items.set("sea",              Translate("GuideItem2"));
	items.set("crate",            Translate("GuideItem3"));
	items.set("revive",           Translate("GuideItem4"));
	items.set("health",           Translate("GuideItem5"));
	items.set("carnage",          Translate("GuideItem6"));
	items.set("teleport",         Translate("GuideItem7"));
	items.set("repair",           Translate("GuideItem8"));
	items.set("midas",            Translate("GuideItem9"));
	items.set("stone",            Translate("GuideItem10"));
	items.set("holygrenade",      Translate("GuideItem11"));
	items.set("shotgun",          Translate("GuideItem12"));
	items.set("bazooka",          Translate("GuideItem13"));
	items.set("flamethrower",     Translate("GuideItem14"));

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

	CRules@ rules = getRules();

	CBlob@ library = getBlobByName("library");
	const string library_tip = library is null ? Translate("GuideVogue1") : Translate("GuideVogue2");
	possible.push_back(library_tip);

	CBlob@ sedgwick = getBlobByName("sedgwick");
	if (sedgwick !is null)
	{
		addRelevantInfo(Translate("GuideVogue3"), @possible, 10);
	}

	CBlob@ portal = getBlobByName("zombieportal");
	if (portal !is null)
	{
		const string portal_tip = portal.hasTag("portal_activated") ? Translate("GuideVogue7") : Translate("GuideVogue6");
		addRelevantInfo(portal_tip, @possible, 10);
	}

	CBlob@ bobert = getBlobByName("bobert");
	if (bobert !is null)
	{
		addRelevantInfo(Translate("GuideVogue5"), @possible, 10);
	}
	else if (rules.get_u16("bobert_day") - rules.get_u16("day_number") < 4)
	{
		addRelevantInfo(Translate("GuideVogue4"), @possible, 3);
	}
	
	CBlob@ enchanter = getBlobByName("enchanter");
	if (enchanter !is null)
	{
		addRelevantInfo(Translate("GuideVogue8"), @possible, 10);
	}

	CInventory@ inv = caller.getInventory();
	if (inv !is null)
	{
		dictionary@ items = getGuideItems();
		for (u16 i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			const string name = item.exists("scroll defname0") ? item.get_string("scroll defname0") : item.getName();

			string description;
			if (items.get(name, description))
			{
				addRelevantInfo(description, @possible, 10);
			}
		}
	}
	
	return possible[XORRandom(possible.length)];
}

void addRelevantInfo(const string&in info, string[]@ possible, const u8&in relevancy)
{
	for (u8 i = 0; i < relevancy; i++)
	{
		possible.push_back(info);
	}
}
