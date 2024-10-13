// Zombie Fortress scrolls

#include "MakeScroll.as";

//   -- ADDING NEW SCROLLS --
// 1) set the scroll information here, such as the name, frame, and scripts the scroll uses.
// 2) add the scroll's scripts to LoadScripts.cfg, otherwise the scripts will not work on server
// 3) test out your scroll by typing '/scroll [scrollname]' in chat

void SetupScrolls(CRules@ this)
{
	ScrollSet _all;
	this.set("all scrolls", _all);
	
	//SCROLLS
	ScrollSet@ all = getScrollSet("all scrolls");

	{
		ScrollDef def;
		def.name = "Scroll of Fowl";
		def.scrollFrame = 1;
		def.scripts.push_back("ScrollFowl.as");
		all.scrolls.set("fowl", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Royalty";
		def.scrollFrame = 3;
		def.scripts.push_back("ScrollRoyalty.as");
		all.scrolls.set("royalty", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Wisent";
		def.scrollFrame = 4;
		def.scripts.push_back("ScrollWisent.as");
		all.scrolls.set("wisent", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Fish";
		def.scrollFrame = 5;
		def.scripts.push_back("ScrollFish.as");
		all.scrolls.set("fish", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Drought";
		def.scrollFrame = 8;
		def.scripts.push_back("ScrollDrought.as");
		all.scrolls.set("drought", def);
	}
	/*{
		ScrollDef def;
		def.name = "Scroll of Chaos";
		def.scrollFrame = 9;
		def.scripts.push_back("ScrollChaos.as");
		all.scrolls.set("chaos", def);
	}*/
	{
		ScrollDef def;
		def.name = "Scroll of Harvest";
		def.scrollFrame = 10;
		def.scripts.push_back("ScrollFlora.as");
		all.scrolls.set("flora", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Resurrection";
		def.scrollFrame = 11;
		def.scripts.push_back("ScrollRevive.as");
		all.scrolls.set("revive", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Compaction";
		def.scrollFrame = 12;
		def.scripts.push_back("ScrollCrate.as");
		all.scrolls.set("crate", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Duplication";
		def.scrollFrame = 14;
		def.scripts.push_back("ScrollClone.as");
		all.scrolls.set("clone", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Repair";
		def.scrollFrame = 15;
		def.scripts.push_back("ScrollRepair.as");
		all.scrolls.set("repair", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Health";
		def.scrollFrame = 17;
		def.scripts.push_back("ScrollHealth.as");
		all.scrolls.set("health", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Carnage";
		def.scrollFrame = 19;
		def.scripts.push_back("ScrollSuddenGib.as");
		all.scrolls.set("carnage", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Midas";
		def.scrollFrame = 20;
		def.scripts.push_back("ScrollMidas.as");
		all.scrolls.set("midas", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Conveyance";
		def.scrollFrame = 21;
		def.scripts.push_back("ScrollTeleport.as");
		all.scrolls.set("teleport", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Sea";
		def.scrollFrame = 22;
		def.scripts.push_back("ScrollSea.as");
		all.scrolls.set("sea", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Quarry";
		def.scrollFrame = 23;
		def.scripts.push_back("ScrollStone.as");
		all.scrolls.set("stone", def);
	}

	all.names = all.scrolls.getKeys();
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
