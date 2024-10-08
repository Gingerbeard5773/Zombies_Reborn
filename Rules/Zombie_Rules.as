// Zombie Fortress generic rules

#define SERVER_ONLY

#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Statistics.as";

u16 days_to_survive = -1; //days players must survive to win, -1 to disable win condition

const u8 GAME_WON = 5;
const u8 nextmap_seconds = 15;
f32 lastDayHour;
u8 seconds_till_nextmap = nextmap_seconds;
bool hitRecord = false;

void onInit(CRules@ this)
{
	Reset(this);
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

	lastDayHour = 0.0f;
	this.set_u16("day_number", 0);
	this.Sync("day_number", true);

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

// Protocols when the day changes
void checkDayChange(CRules@ this)
{
	const f32 dayHour = Maths::Roundf(getMap().getDayTime()*10)/10;
	if (dayHour == lastDayHour) return;
	lastDayHour = dayHour;

	if (dayHour != this.daycycle_start) return;

	const u16 dayNumber = this.get_u16("day_number") + 1;
	this.set_u16("day_number", dayNumber);
	this.Sync("day_number", true);
	
	bool new_record;
	const u16 recordDay = server_getRecordDay(dayNumber, new_record);

	//end game if we reached the last day
	if (dayNumber >= days_to_survive)
	{
		this.SetCurrentState(GAME_WON);
		string[] inputs = {dayNumber+""};
		getEndGameStatistics(this, @inputs);
		server_SendGlobalMessage(this, 2, nextmap_seconds, inputs);
	}
	else if (new_record && !hitRecord)
	{
		hitRecord = true;
		const string[] inputs = {dayNumber+""};
		server_SendGlobalMessage(this, 7, 10, inputs);
	}
	else 
	{
		const string[] inputs = {dayNumber+""};
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

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if (getPlayersCount() <= 1) return;

	checkGameEnded(this, player);
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
	if (!isGameLost(player)) return;
	
	this.SetCurrentState(GAME_OVER);
	string[] inputs = {dayNumber+""};
	getEndGameStatistics(this, @inputs);
	server_SendGlobalMessage(this, 1, nextmap_seconds, inputs);
}

// Check if we lost the game
const bool isGameLost(CPlayer@ player)
{
	bool noAlivePlayers = true;
	
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ ply = getPlayer(i);
		if (ply is null || ply is player) continue;
		
		CBlob@ plyBlob = ply.getBlob();
		if (plyBlob !is null && !plyBlob.hasTag("undead") && !plyBlob.hasTag("dead"))
		{
			noAlivePlayers = false;
			break;
		}
	}
	
	return noAlivePlayers;
}
