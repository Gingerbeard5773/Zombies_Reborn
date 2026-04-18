// Zombie Fortress scrolls

#include "MakeScroll.as"
#include "Zombie_Translation.as"

//   -- ADDING NEW SCROLLS --
// 1) set the scroll information here, such as the name, frame, and scripts the scroll uses.
// 2) add the scroll's scripts to LoadScripts.cfg, otherwise the scripts will not work on server
// 3) test out your scroll by typing '/scroll [scrollname]' in chat

void SetupScrolls(CRules@ this)
{
	if (this.exists("all scrolls")) return;

	ScrollSet _all, _basic;
	this.set("all scrolls", _all);
	this.set("basic scrolls", _basic);
	
	//SCROLLS
	ScrollSet@ all = getScrollSet("all scrolls");
	ScrollSet@ basic = getScrollSet("basic scrolls");

	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 0;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("something", def);
	}*/
	{
		ScrollDef def;
		def.name = name(Translate::ScrollFowl);
		def.scrollFrame = 1;
		def.scripts.push_back("ScrollFowl.as");
		all.scrolls.set("fowl", def);
		basic.scrolls.set("fowl", def);
	}
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 2;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("something", def);
	}*/
	{
		ScrollDef def;
		def.name = name(Translate::ScrollRoyalty);
		def.scrollFrame = 3;
		def.scripts.push_back("ScrollRoyalty.as");
		all.scrolls.set("royalty", def);
		basic.scrolls.set("royalty", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollWisent);
		def.scrollFrame = 4;
		def.scripts.push_back("ScrollWisent.as");
		all.scrolls.set("wisent", def);
		basic.scrolls.set("wisent", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollFish);
		def.scrollFrame = 5;
		def.scripts.push_back("ScrollFish.as");
		all.scrolls.set("fish", def);
		basic.scrolls.set("fish", def);
	}
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 6;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("something", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 7;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("something", def);
	}*/
	{
		ScrollDef def;
		def.name = "Scroll of Drought";
		def.scrollFrame = 8;
		def.scripts.push_back("ScrollDrought.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("drought", def);
		basic.scrolls.set("drought", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollHealth);
		def.scrollFrame = 9;
		def.scripts.push_back("ScrollHealth.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("health", def);
		basic.scrolls.set("health", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollFlora);
		def.scrollFrame = 10;
		def.scripts.push_back("ScrollFlora.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("flora", def);
		basic.scrolls.set("flora", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollRevive);
		def.scrollFrame = 11;
		def.scripts.push_back("ScrollRevive.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("revive", def);
		basic.scrolls.set("revive", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollCrate);
		def.scrollFrame = 12;
		def.scripts.push_back("ScrollCrate.as");
		all.scrolls.set("crate", def);
		basic.scrolls.set("crate", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollTeleport);
		def.scrollFrame = 13;
		def.scripts.push_back("ScrollTeleport.as");
		all.scrolls.set("teleport", def);
		basic.scrolls.set("teleport", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollClone);
		def.scrollFrame = 14;
		def.scripts.push_back("ScrollClone.as");
		all.scrolls.set("clone", def);
		basic.scrolls.set("clone", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollRepair);
		def.scrollFrame = 15;
		def.scripts.push_back("ScrollRepair.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("repair", def);
		basic.scrolls.set("repair", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollDesiccation);
		def.scrollFrame = 16;
		def.scripts.push_back("ScrollDesiccation.as");
		all.scrolls.set("desiccation", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollResurgence);
		def.scrollFrame = 17;
		def.scripts.push_back("ScrollResurgence.as");
		all.scrolls.set("resurgence", def);
	}
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 18;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("something", def);
	}*/
	{
		ScrollDef def;
		def.name = "Scroll of Carnage";
		def.scrollFrame = 19;
		def.scripts.push_back("ScrollSuddenGib.as");
		all.scrolls.set("carnage", def);
		basic.scrolls.set("carnage", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollMidas);
		def.scrollFrame = 20;
		def.scripts.push_back("ScrollMidas.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("midas", def);
		basic.scrolls.set("midas", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollTime);
		def.scrollFrame = 21;
		def.scripts.push_back("ScrollTime.as");
		all.scrolls.set("time", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollSea);
		def.scrollFrame = 22;
		def.scripts.push_back("ScrollSea.as");
		all.scrolls.set("sea", def);
		basic.scrolls.set("sea", def);
	}
	{
		ScrollDef def;
		def.name = name(Translate::ScrollStone);
		def.scrollFrame = 23;
		def.scripts.push_back("ScrollStone.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("stone", def);
		basic.scrolls.set("stone", def);
	}
	
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 24;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("stone", def);
	} */
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 25;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("stone", def);
	} */
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 26;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("stone", def);
	} */
	{
		ScrollDef def;
		def.name = name(Translate::ScrollObliteration);
		def.scrollFrame = 27;
		def.scripts.push_back("ScrollObliteration.as");
		all.scrolls.set("obliteration", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Gilding";
		def.scrollFrame = 28;
		def.scripts.push_back("ScrollGilding.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("gilding", def);
	}
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 29;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("stone", def);
	} */
	/*{
		ScrollDef def;
		def.name = "Scroll of Something";
		def.scrollFrame = 30;
		def.scripts.push_back("ScrollSomething.as");
		all.scrolls.set("stone", def);
	} */
	{
		ScrollDef def;
		def.name = name(Translate::ScrollIron);
		def.scrollFrame = 31;
		def.scripts.push_back("ScrollIron.as");
		def.scripts.push_back("ScrollRangeIndicator.as");
		all.scrolls.set("iron", def);
	}

	all.names = all.scrolls.getKeys();
	basic.names = basic.scrolls.getKeys();
	SetupScrollIcons(all);
}

void SetupScrollIcons(ScrollSet@ all)
{
	const u8 namesLength = all.names.length;
	for (u8 i = 0; i < namesLength; i++)
	{
		ScrollDef@ def;
		if (!all.scrolls.get(all.names[i], @def)) continue;
		
		AddIconToken("$scroll_" + all.names[i] + "$", "Scroll.png", Vec2f(16, 16), def.scrollFrame);
	}
}
