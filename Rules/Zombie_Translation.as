// Zombie Fortress translations

//works by seperating each language by token '\\'
//all translations are only set on startup, therefore changing language mid-game will not update the strings

shared const string Translate(const string&in words)
{
	string[]@ tokens = words.split("\\");
	if (g_locale == "en") //english
		return tokens[0];
	/*if (g_locale == "ru") //russian
		return tokens[1];
	if (g_locale == "br") //porteguese
		return tokens[2];
	if (g_locale == "pl") //polish
		return tokens[3];
	if (g_locale == "fr") //french
		return tokens[4];
	if (g_locale == "es") //spanish
		return tokens[5];*/
	
	return tokens[0];
}

namespace ZombieDesc
{
	const string
	
	//descriptions
	ballista            = Translate("A bolt-firing siege engine, requiring a crew of two. Allows class change."),
	bomber              = Translate("A balloon capable of flying two passengers."),
	mounted_bow         = Translate("A portable arrow-firing death machine. Can be attached to some vehicles."),
	
	windmill            = Translate("Wind Mill\nA grain mill for producing flour."),
	kitchen             = Translate("Kitchen\nCreate various foods for healing."),
	nursery             = Translate("Nursery\nA plant nursery for agricultural purposes."),
	
	bread               = Translate("Bread\nDelicious crunchy whole-wheat bread.\n$heart_full$$heart_half$"),
	cake                = Translate("Cake\nFluffy cake made from egg and wheat.\n$heart_full$$heart_full$$heart_full$"),
	cooked_fish         = Translate("Cooked Fish\nA cooked fish on a stick.\n$heart_full$$heart_full$$heart_full$"),
	cooked_steak        = Translate("Cooked Steak\nA meat chop with sauce.\n$heart_full$$heart_full$$heart_full$$heart_half$"),
	burger              = Translate("Burger\nSeared meat in a bun, bisons love it!\n$heart_full$$heart_full$$heart_full$$heart_full$"),
	
	scroll_fowl         = Translate("Use this to summon a flock of chickens."),
	scroll_flora        = Translate("Use this to create plants nearby."),
	scroll_fish         = Translate("Use this to summon a shark."),
	scroll_revive       = Translate("Use this near a dead body to ressurect them."),
	scroll_clone        = Translate("Use this to duplicate an object you are pointing to."),
	scroll_royalty      = Translate("Use this to summon a geti."),
	scroll_crate        = Translate("Use this to crate an object you are pointing at."),
	scroll_wisent       = Translate("Use this to summon a bison."),
	scroll_teleport     = Translate("Use this to teleport to the area you are pointing to."),
	scroll_sea          = Translate("Use this to generate a source of water."),
	scroll_stone        = Translate("Use this to convert nearby stone into thick stone."),
	
	//flying merchant
	fowl_desc           = Translate("Birds."),
	drought_desc        = Translate("Unplug the drain."),
	flora_desc          = Translate("Perfect for salads."),
	fish_desc           = Translate("It says something about ocean animals."),
	revive_desc         = Translate("Bring back a friend of yours, or maybe even yourself."),
	clone_desc          = Translate("This one is absolutely crazy."),
	royalty_desc        = Translate("I forgot what this one did."),
	wisent_desc         = Translate("Somehow conceals a heffer."),
	crate_desc          = Translate("Put anything in a box."),
	teleport_desc       = Translate("Messes with time and space."),
	carnage_desc        = Translate("Sedgewick really doesn't want me to have this."),
	midas_desc          = Translate("Makes the rocks shiny."),
	sea_desc            = Translate("Flood season!"),
	stone_desc          = Translate("Rocks."),
	
	//scoreboard
	day                 = Translate("Day"),
	zombie_count        = Translate("Zombies: {ZOMBIECOUNT}"),
	open_manual         = Translate("Press {KEY} to toggle the help manual on/off."),
	
	//respawning
	respawn             = Translate("Waiting for dawn..."),
	
	//manual
	title               = Translate("ZOMBIE FORTRESS"),
	tips                = Translate("TIPS"),
	mod_version         = Translate("Version"),
	game_mode           = Translate("Build a great castle and endure the masses of zombies!"),
	change_page         = Translate("Press the arrow buttons to switch between pages."),
	tip_gateways        = Translate("When night arrives, the undead will appear at these gateways."),
	tip_zombification   = Translate("A dead body will transform into a zombie after some time."),
	tip_water_wraith    = Translate("Use water to temporarily stop a burning wraith."),
	tip_headshot        = Translate("Head shots deal additional damage."),
	tip_merchant        = Translate("If there is not many zombies, a trader will visit at mid-day.");
}

const string[] teams =
{
	Translate("Survivors")
};
