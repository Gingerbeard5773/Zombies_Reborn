// Zombie Fortress scrolls

#include "MakeScroll.as";
#include "MiniIconsInc.as";

//   -- ADDING NEW SCROLLS --
// 1) set the scroll information here, such as the name, frame, and scripts the scroll uses.
// 2) create the scripts the scroll will use.
// 3) add the scroll's scripts to LoadScripts.cfg, otherwise the scripts will not work on server
// 4) test out your scroll by typing '!scroll [scrollname]' in chat

void SetupScrolls(CRules@ this)
{
	ScrollSet _all, _tech;
	this.set("all scrolls", _all);
	this.set("factory options", _tech);
	
	//SCROLLS
	ScrollSet@ all = getScrollSet("all scrolls");

	{
		ScrollDef def;
		def.name = "Scroll of Fowl";
		def.scrollFrame = 2;
		def.scripts.push_back("ScrollFowl.as");
		all.scrolls.set("fowl", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Drought";
		def.scrollFrame = 4;
		def.scripts.push_back("ScrollDrought.as");
		all.scrolls.set("drought", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Harvest";
		def.scrollFrame = 5;
		def.scripts.push_back("ScrollFlora.as");
		all.scrolls.set("flora", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Fish";
		def.scrollFrame = 6;
		def.scripts.push_back("ScrollFish.as");
		all.scrolls.set("fish", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Resurrection";
		def.scrollFrame = 7;
		def.scripts.push_back("ScrollRevive.as");
		all.scrolls.set("revive", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Duplication";
		def.scrollFrame = 10;
		def.scripts.push_back("ScrollClone.as");
		all.scrolls.set("clone", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Royalty";
		def.scrollFrame = 11;
		def.scripts.push_back("ScrollRoyalty.as");
		all.scrolls.set("royalty", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Compaction";
		def.scrollFrame = 13;
		def.scripts.push_back("ScrollCrate.as");
		all.scrolls.set("crate", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Wisent";
		def.scrollFrame = 17;
		def.scripts.push_back("ScrollWisent.as");
		all.scrolls.set("wisent", def);
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
		def.name = "Scroll of Carnage";
		def.scrollFrame = 24;
		def.scripts.push_back("ScrollSuddenGib.as");
		all.scrolls.set("carnage", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Midas";
		def.scrollFrame = 25;
		def.scripts.push_back("ScrollMidas.as");
		all.scrolls.set("midas", def);
	}
	{
		ScrollDef def;
		def.name = "Scroll of Quarry";
		def.scrollFrame = 26;
		def.scripts.push_back("ScrollStone.as");
		all.scrolls.set("stone", def);
	}

	//FACTORIES
	ScrollSet@ tech = getScrollSet("factory options");

	{
		ScrollDef def;
		def.name = "Bombs";
		def.level = 50;
		def.scrollFrame = FactoryFrame::military_basics;
		addScrollItemsToArray("Bombs", "mat_bombs", 30, false, 3, @def.items);
		tech.scrolls.set("military basics", def);
	}
	{
		ScrollDef def;
		def.name = "Catapult";
		def.level = 50;
		def.scrollFrame = FactoryFrame::catapult;
		addScrollItemsToArray("Catapult", "catapult", 60, true, 1, @def.items);
		tech.scrolls.set("catapult", def);
	}
	{
		ScrollDef def;
		def.name = "Ballista";
		def.level = 100;
		def.scrollFrame = FactoryFrame::ballista;
		addScrollItemsToArray("Ballista", "ballista", 60, true, 1, @def.items);
		addScrollItemsToArray("Ballista Bolts", "mat_bolts", 60, false, 1, @def.items);
		addScrollItemsToArray("Ballista Shells", "mat_bomb_bolts", 60, false, 1, @def.items);
		tech.scrolls.set("ballista", def);
	}
	{
		ScrollDef def;
		def.name = "Bomber";
		def.level = 150;
		def.scrollFrame = FactoryFrame::mounted_bow + 1;
		addScrollItemsToArray("Bomber", "bomber", 80, true, 1, @def.items);
		tech.scrolls.set("bomber", def);
	}
	{
		ScrollDef def;
		def.name = "Mounted Bow";
		def.level = 50;
		def.scrollFrame = FactoryFrame::mounted_bow;
		addScrollItemsToArray("Mounted Bow", "mounted_bow", 40, true, 2, @def.items);
		tech.scrolls.set("mounted_bow", def);
	}
	{
		ScrollDef def;
		def.name = "Demolition";
		def.scrollFrame = FactoryFrame::explosives;
		def.level = 100;
		addScrollItemsToArray("Keg", "keg", 60, false, 1, @def.items);
		addScrollItemsToArray("Mine", "mine", 60, false, 2, @def.items);
		tech.scrolls.set("explosives", def);
	}
	{
		ScrollDef def;
		def.name = "Pyrotechnics";
		def.scrollFrame = FactoryFrame::pyro;
		def.level = 50;
		addScrollItemsToArray("Molotov", "molotov", 25, false, 3, @def.items);
		addScrollItemsToArray("Molotov Arrows", "mat_molotovarrows", 25, false, 3, @def.items);
		tech.scrolls.set("pyro", def);
	}
	{
		ScrollDef def;
		def.name = "Water Ammo";
		def.scrollFrame = FactoryFrame::water_ammo;
		def.level = 25;
		addScrollItemsToArray("Water Arrows", "mat_waterarrows", 25, false, 1, @def.items);
		addScrollItemsToArray("Water Bombs", "mat_waterbombs", 20, false, 1, @def.items);
		tech.scrolls.set("water ammo", def);
	}
	{
		ScrollDef def;
		def.name = "Bomb Arrows";
		def.scrollFrame = FactoryFrame::expl_ammo;
		def.level = 50;
		addScrollItemsToArray("Bomb Arrows", "mat_bombarrows", 35, false, 2, @def.items);
		tech.scrolls.set("bomb ammo", def);
	}

	all.names = all.scrolls.getKeys();
	tech.names = tech.scrolls.getKeys();
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
