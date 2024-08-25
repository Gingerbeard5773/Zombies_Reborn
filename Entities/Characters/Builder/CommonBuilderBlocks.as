// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array,
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2)
// Add a new string to PAGE_NAME in
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);

#include "BuildBlock.as"
#include "Requirements.as"
#include "Costs.as"
#include "TeamIconToken.as"
#include "CustomTiles.as"

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks(BuildBlock[][]@ blocks, int team_num = 0, const string&in gamemode_override = "")
{
	InitCosts();
	CRules@ rules = getRules();

	AddIconToken("$iron_block$", "World.png", Vec2f(8, 8), CMap::tile_iron);
	AddIconToken("$biron_block$", "World.png", Vec2f(8, 8), CMap::tile_biron);
	AddIconToken("$iron_platform$", "IronPlatform.png", Vec2f(8, 8), 0);

	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block\nBasic building block");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::stone_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall\nExtra support");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::back_stone_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", getTeamIcon("stone_door", "1x1StoneDoor.png", team_num, Vec2f(16, 8)), "Stone Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::stone_door);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block\nCheap block\nwatch out for fire!");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall\nCheap extra support");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::back_wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", getTeamIcon("wooden_door", "1x1WoodDoor.png", team_num, Vec2f(16, 8)), "Wooden Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_door);
		blocks[0].push_back(b);
	}
	/*{
		BuildBlock b(0, "trap_block", getTeamIcon("trap_block", "TrapBlock.png", team_num), "Trap Block\nOnly enemies can pass");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::trap_block);
		blocks[0].push_back(b);
	}*/
	{
		BuildBlock b(0, "bridge", getTeamIcon("bridge", "Bridge.png", team_num), "Trap Bridge\nOnly your team can stand on it");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::bridge);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder\nAnyone can climb it");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::ladder);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform\nOne way platform");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_platform);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "building", "$building$", "Workshop\nStand in an open space\nand tap this button.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", CTFCosts::workshop_wood);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "spikes", "$spikes$", "Spikes\nPlace on Stone Block\nfor Retracting Trap");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::spikes);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_iron, "iron_block", "$iron_block$", "Iron Block\nResistant to explosions.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_biron, "biron_block", "$biron_block$", "Back Iron Wall\nDurable Support.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 1);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_door", getTeamIcon("iron_door", "1x1IronDoor.png", team_num, Vec2f(16, 8)), "Iron Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 4);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_platform", "$iron_platform$", "Iron Platform\nOne way platform");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 3);
		blocks[0].push_back(b);
	}
	
	BuildBlock[] page_1;
	blocks.push_back(page_1);
	{
		BuildBlock b(0, "windmill", getTeamIcon("windmill", "WindMill.png", team_num, Vec2f(64, 102), 1), "Wind Mill\nA grain mill for producing flour.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 250);
		b.buildOnGround = true;
		b.size.Set(32, 72);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "kitchen", getTeamIcon("kitchen", "Kitchen.png", team_num, Vec2f(40, 32)), "Kitchen\nCreate various foods for healing.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 100);
		b.buildOnGround = true;
		b.size.Set(40, 32);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "forge", getTeamIcon("forge", "Forge.png", team_num, Vec2f(56, 40)), "Forge\nSmelt raw ore into ingots.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 300);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 200);
		b.buildOnGround = true;
		b.size.Set(56, 40);
		blocks[1].push_back(b);
	}	
	{
		BuildBlock b(0, "nursery", getTeamIcon("nursery", "Nursery.png", team_num, Vec2f(40, 32)), "Nursery\nA plant nursery for agricultural purposes.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood\n", 400);
		AddRequirement(b.reqs, "blob", "seed", "Seed", 1);
		b.buildOnGround = true;
		b.size.Set(40, 32);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "armory", getTeamIcon("armory", "Armory.png", team_num, Vec2f(56, 40)), "Armory\nBuild weapons and change your class.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood\n", 300);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 200);
		b.buildOnGround = true;
		b.size.Set(56, 40);
		blocks[1].push_back(b);
	}
	/*{
		BuildBlock b(0, "library", getTeamIcon("library", "LibraryIcon.png", team_num, Vec2f(32, 19)), "Library\nA place of study to obtain new technologies.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood\n", 300);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 150);
		AddRequirement(b.reqs, "blob", "mat_gold", "Gold", 50);
		b.buildOnGround = true;
		b.size.Set(56, 40);
		blocks[1].push_back(b);
	}*/
}

ConfigFile@ openBlockBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/BlockBindings.cfg"))
	{
		// write EmoteBinding.cfg to Cache
		cfg.saveFile("BlockBindings.cfg");

	}

	return cfg;
}

u8 read_block(ConfigFile@ cfg, string name, u8 default_value)
{
	u8 read_val = cfg.read_u8(name, default_value);
	return read_val;
}
