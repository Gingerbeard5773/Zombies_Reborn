// Zombie Fortress generic rules

#define SERVER_ONLY

#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_DaysCommon.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"
#include "GetSurvivors.as"

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

void onReload(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	ConfigFile@ cfg = Statistics::openConfig();
	const u16 record_day = cfg.exists("record_day") ? cfg.read_u16("record_day") : 1;

	this.set_u16("day_record", record_day);
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

	ConfigFile@ cfg = Statistics::openConfig();
	const u16 record_day = cfg.exists("record_day") ? cfg.read_u16("record_day") : 1;
	if (day_number > record_day)
	{
		cfg.add_u16("record_day", day_number);
		cfg.add_u16("record_day_previous", record_day);
		cfg.saveFile(Statistics::filename);
	}

	if (day_number == 10)
	{
		Achievement::server_Unlock(Achievement::Surviving);
	}
	else if (day_number == 25)
	{
		Achievement::server_Unlock(Achievement::Thriving);
	}
	else if (day_number == 50)
	{
		Achievement::server_Unlock(Achievement::GettingDangerous);
	}
	else if (day_number == 75)
	{
		Achievement::server_Unlock(Achievement::Extreme);
	}
	else if (day_number == 100)
	{
		Achievement::server_Unlock(Achievement::Impossible);
	}

	if (day_number > record_day && !hitRecord)
	{
		Achievement::server_Unlock(Achievement::WorldRecord);
		hitRecord = true;
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, 7, 10, inputs);
	}
	else 
	{
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, 0, 10, inputs);
	}
	
	if (this.get_u8("survivor player count") >= 6 && day_number > 5)
	{
		CBlob@[]@ survivors = getSurvivors();
		if (survivors.length == 1)
		{
			CPlayer@ player = survivors[0].getPlayer();
			if (player !is null)
			{
				Achievement::server_Unlock(Achievement::SoleSurvivor, player);
			}
		}
	}
}

// Protocols for when the game ends
void onGameEnd(CRules@ this)
{
	//timer till next map
	if (this.getCurrentState() != GAME_OVER) return;

	if (seconds_till_nextmap-- == 0)
	{
		LoadNextMap();
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
