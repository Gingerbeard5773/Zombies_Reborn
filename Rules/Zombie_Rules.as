// Zombie Fortress generic rules

#define SERVER_ONLY

u16 days_to_survive = 15;     //days players must survive to win, as well as the power creep of zombies
bool infinite_days = false;  //decide if the game ends at days_to_survive

const u8 GAME_WON = 5;
const u8 nextmap_seconds = 15;
f32 lastDayHour;
u8 seconds_till_nextmap = nextmap_seconds;

void onInit(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		//edit these vars in Zombie_Vars.cfg
		days_to_survive = cfg.exists("days_to_survive") ? cfg.read_u16("days_to_survive")  : 15;
		infinite_days   = cfg.exists("infinite_days")   ? cfg.read_bool("infinite_days")  : false;
	}
	
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	lastDayHour = 0.0f;
	this.set_u16("day_number", 0);
	this.Sync("day_number", true);

	seconds_till_nextmap = nextmap_seconds;
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

	//end game if we reached the last day
	if (dayNumber >= days_to_survive && !infinite_days)
	{
		this.SetCurrentState(GAME_WON);
		setTimedGlobalMessage(this, 2, nextmap_seconds);
	}
	else
	{
		setTimedGlobalMessage(this, 0, 10);
	}

	this.set_u16("day_number", dayNumber);
	this.Sync("day_number", true);
}

// Set a global message with a timer to remove itself
void setTimedGlobalMessage(CRules@ this, const u8&in index, const u8&in seconds)
{
	//consult Zombie_GlobalMessages.as
	this.set_u8("global_message_index", index);
	this.set_u8("global_message_timer", seconds);
	this.Sync("global_message_index", true);
	this.Sync("global_message_timer", true);
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
	checkGameEnded(this, player);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	checkGameEnded(this, victim);
}

void checkGameEnded(CRules@ this, CPlayer@ player)
{
	if (this.get_u16("day_number") < 2) return;
	
	//have all players died?
	if (!isGameLost(player)) return;
	
	this.SetCurrentState(GAME_OVER);
	setTimedGlobalMessage(this, 1, nextmap_seconds);
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
