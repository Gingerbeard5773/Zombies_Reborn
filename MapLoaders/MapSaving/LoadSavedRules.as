// Gingerbeard @ November 23, 2024

//this script MUST be the last script to be called in gamemode.cfg

#define SERVER_ONLY

#include "MapSaver.as"
#include "Zombie_DaysCommon.as"

void onInit(CRules@ this)
{
	Reset(this);

	addOnNewDayHour(this, @onNewDayHour);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	LoadSavedRules(this, getMap());
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	//Auto-save the map once a day
	if (day_hour != 4) return;

	print("AUTOSAVING MAP; DAY " + this.get_u16("day_number"), 0xff66C6FF);
	SaveMap(this, getMap());
}
