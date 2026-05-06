// Gingerbeard @ November 23, 2024

//this script MUST be the last script to be called in gamemode.cfg

#include "MapSaver.as"
#include "Zombie_DaysCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "PlayerPermissions.as"

const u8 TIME_TRAVEL_DAYS = 2; // also edit ScrollRewind.as to fully change this

void onInit(CRules@ this)
{
	this.addCommandID("server_load_save");

	if (!isServer()) return;

	addOnNewDayHour(this, @onNewDayHour);

	LoadSavedRules(this, getMap());
}

void onRestart(CRules@ this)
{
	if (!isServer()) return;

	LoadSavedRules(this, getMap());

	if (this.exists("time_travel_netid") && this.get_netid("time_travel_netid") > 0)
	{
		server_SendGlobalSound(this, "Revive.ogg");
		server_SendGlobalMessage(this, "ScrollRewindFinish", 8, ConsoleColour::CRAZY.color);

		const string[] inputs = {this.get_u16("day_number")+""};
		server_SendGlobalMessage(this, "Day", 8, inputs);

		this.set_netid("time_travel_netid", 0);

		// overwrite the save so our time travel scroll can't ever reappear 
		SaveMap(this, getMap(), this.get_string("mapsaver_save_slot"));
	}
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	const u16 day_number = this.get_u16("day_number");

	// standard auto-save
	if (day_hour == 4)
	{
		print("AUTOSAVING MAP: AutoSave [DAY " + day_number + "]", 0xff66C6FF);
		SaveMap(this, getMap());
	}

	// time travel auto-saves
	if (day_hour == 3)
	{
		const u16 num = day_number % (TIME_TRAVEL_DAYS + 1);
		print("AUTOSAVING MAP: TimeSave" + num + " [DAY " + day_number + "]", 0xff66C6FF);
		SaveMap(this, getMap(), "TimeSave"+num);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_load_save") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		bool isAdmin, isSuperAdmin;
		getPermissions(player, isAdmin, isSuperAdmin);

		if (!isAdmin && !isSuperAdmin) return;

		SaveFile@ save = SaveFile();
		if (!save.Unserialize(params)) { error("Failed to read save file [LoadSavedRules]"); return; }

		print("LOADING SAVED MAP FROM CLIENT: "+player.getUsername(), 0xff66C6FF);

		ConfigFile@ config = ConfigFile();
		save.Write(config);
		config.saveFile(Save::SaveFileName + "ClientRequest");

		this.set_string("mapsaver_save_slot", "ClientRequest");
		this.set_bool("loaded_saved_map", false);
		LoadNextMap();
	}
}
