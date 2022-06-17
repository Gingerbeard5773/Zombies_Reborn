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
	
	//vehicles
	ballista            = Translate("A bolt-firing siege engine, requiring a crew of two. Allows class change."),
	bomber              = Translate("A balloon capable of flying two passengers."),
	mounted_bow         = Translate("A portable arrow-firing death machine. Can be attached to some vehicles."),
	
	//scoreboard
	day                 = Translate("Day"),
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
	tip_headshot        = Translate("Head shots deal additional damage.");
}

const string[] teams =
{
	Translate("Survivors")
};
