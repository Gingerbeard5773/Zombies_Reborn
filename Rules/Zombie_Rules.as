// Zombie Fortress generic rules

#define SERVER_ONLY

#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Statistics.as";
#include "Zombie_DaysCommon.as";
#include "GetSurvivors.as";

u16 days_to_survive = -1; //days players must survive to win, -1 to disable win condition

const u8 GAME_WON = 5;
const u8 nextmap_seconds = 15;
u8 seconds_till_nextmap = nextmap_seconds;
bool hitRecord = false;

void onInit(CRules@ this)
{
	Reset(this);

	onNewDayHourHandle@[] handles;
	this.set("onNewDayHour handles", @handles);

	addOnNewDayHour(this, @onNewDayHour);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		days_to_survive = cfg.exists("days_to_survive") ? cfg.read_u16("days_to_survive") : -1;
	}
	
	this.set_u16("day_record", server_getRecordDay());
	this.Sync("day_record", true);

	this.set_u16("day_number", 0);
	this.Sync("day_number", true);

	this.set_u16("last_day_hour", 0);

	seconds_till_nextmap = nextmap_seconds;
	hitRecord = false;
	this.SetCurrentState(GAME);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	//set new player to survivors
	player.server_setTeamNum(0);
}

void onTick(CRules@ this)
{
	if (getGameTime() % getTicksASecond() == 0) //once every second
	{
		checkDayChange(this);

		onGameEnd(this);
	}
}

void checkDayChange(CRules@ this)
{
	const u16 day_hour = Maths::Roundf(getMap().getDayTime()*10);
	if (day_hour == this.get_u16("last_day_hour")) return;

	const u16 day_number = this.get_u16("day_number");

	onNewDayHourHandle@[]@ handles;
	if (this.get("onNewDayHour handles", @handles))
	{
		for (u8 i = 0; i < handles.length; ++i)
		{
			handles[i](this, day_number, day_hour);
		}
	}

	this.set_u16("last_day_hour", day_hour);
}

// Protocols when the day changes
void onNewDayHour(CRules@ this, u16 day_number, u16 day_hour)
{
	if (day_hour != this.daycycle_start*10) return;

	day_number++;
	this.set_u16("day_number", day_number);
	this.Sync("day_number", true);

	bool new_record;
	const u16 recordDay = server_getRecordDay(day_number, new_record);

	//end game if we reached the last day
	if (day_number >= days_to_survive)
	{
		this.SetCurrentState(GAME_WON);
		string[] inputs = {day_number+""};
		getEndGameStatistics(this, @inputs);
		server_SendGlobalMessage(this, 2, nextmap_seconds, inputs);
	}
	else if (new_record && !hitRecord)
	{
		hitRecord = true;
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, 7, 10, inputs);
	}
	else 
	{
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, 0, 10, inputs);
	}
}

// Protocols for when the game ends
void onGameEnd(CRules@ this)
{
	const u8 GAME_STATE = this.getCurrentState();
	
	//timer till next map
	if (GAME_STATE == GAME_OVER || GAME_STATE == GAME_WON)
	{
		seconds_till_nextmap--;
		if (seconds_till_nextmap == 0)
		{
			LoadNextMap();
		}
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	checkGameEnded(this, victim);
}

void checkGameEnded(CRules@ this, CPlayer@ player)
{
	const u16 dayNumber = this.get_u16("day_number");
	if (dayNumber < 2) return;

	//have all players died?
	if (getSurvivors(player).length > 0) return;

	//make certain we only set game end once
	if (this.getCurrentState() == GAME_OVER) return;
	
	this.SetCurrentState(GAME_OVER);
	string[] inputs = {dayNumber+""};
	getEndGameStatistics(this, @inputs);
	server_SendGlobalMessage(this, 1, nextmap_seconds, inputs);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	antiSpectatorCamping(player);
}

void antiSpectatorCamping(CPlayer@ excluded = null)
{
	CPlayer@[] players; getSurvivors(@players, excluded);
	if (players.length > 0) return;
	
	CPlayer@[] spectators = getSpectators(excluded);
	if (spectators.length <= 0) return;
	
	CPlayer@ random_player = spectators[XORRandom(spectators.length)];
	random_player.server_setTeamNum(0);
}
