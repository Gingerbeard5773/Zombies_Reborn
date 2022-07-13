// Zombie Fortress generic rules

#define SERVER_ONLY

const u8 warmup_days = 2;       //days of warmup-time we give to players
const u8 days_to_survive = 15;  //days players must survive to win

const u8 GAME_WON = 5;
const u8 nextmap_seconds = 15;
u8 seconds_till_nextmap = nextmap_seconds;

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
	this.set_u8("day_number", 1);
	this.set_u8("message_timer", 1);
	
	seconds_till_nextmap = nextmap_seconds;
	this.SetCurrentState(WARMUP);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	//set new player to survivors
	player.server_setTeamNum(0);
}

void onTick(CRules@ this)
{
	CMap@ map = getMap();
	
	const u32 gameTime = getGameTime();
	const u32 day_cycle = this.daycycle_speed * 60;
	const u8 dayNumber = (gameTime / getTicksASecond() / day_cycle) + 1;
	
	//spawn zombies at night-time
	const f32 difficulty = 2.0f * dayNumber; //default 2.0
	const u32 spawnRate = Maths::Max(8, getTicksASecond() * (6 - difficulty / 2.2f)); //default 2.0
	
	if (gameTime % spawnRate == 0)
	{
		spawnZombie(map);
	}
	
	if (gameTime % getTicksASecond() == 0) //once every second
	{
		checkDayChange(this, dayNumber);
		
		onGameEnd(this);
		
		resetTimedGlobalMessage(this);
	}
}

// Spawn various zombie blobs on the map
void spawnZombie(CMap@ map)
{
	if (map.getDayTime() > 0.8f || map.getDayTime() < 0.1f)
	{
		const u32 r = XORRandom(100);
		
		string blobname = "skeleton"; //leftover       // 40%
		
		if (r >= 95)       blobname = "greg";          // 5%
		else if (r >= 90)  blobname = "wraith";        // 5%
		else if (r >= 75)  blobname = "zombieknight";  // 15%
		else if (r >= 40)  blobname = "zombie";        // 35%
		
		server_CreateBlob(blobname, -1, getZombieSpawnPos(map));
	}
}

// Decide where zombies spawn
Vec2f getZombieSpawnPos(CMap@ map)
{
	Vec2f[] spawns;
	map.getMarkers("zombie_spawn", spawns);
	
	if (spawns.length <= 0)
	{
		Vec2f dim = map.getMapDimensions();
		const u32 margin = 10;
		const Vec2f offset = Vec2f(0, -8);
		
		Vec2f side;
		
		map.rayCastSolid(Vec2f(margin, 0.0f), Vec2f(margin, dim.y), side);
		spawns.push_back(side + offset);
		
		map.rayCastSolid(Vec2f(dim.x-margin, 0.0f), Vec2f(dim.x-margin, dim.y), side);
		spawns.push_back(side + offset);
	}
	
	return spawns[XORRandom(spawns.length)];
}

// Protocols when the day changes
void checkDayChange(CRules@ this, const u8&in dayNumber)
{
	//has the day changed?
	if (dayNumber != this.get_u8("day_number"))
	{
		string dayMessage = "Day "+dayNumber;
		
		//end warmup phase
		if (dayNumber == warmup_days)
		{
			dayMessage = "Warmup over. Day "+dayNumber;
			this.SetCurrentState(GAME);
		}
		
		setTimedGlobalMessage(this, dayMessage, 10);
		
		//end game if we reached the last day
		if (dayNumber >= days_to_survive)
		{
			dayMessage = "Day "+days_to_survive+" Reached! You win!";
			this.SetCurrentState(GAME_WON);
			
			setTimedGlobalMessage(this, dayMessage, nextmap_seconds);
		}
		
		this.set_u8("day_number", dayNumber);
		this.Sync("day_number", true);
	}
}

// Set a global message with a timer to remove itself
void setTimedGlobalMessage(CRules@ this, const string&in text, const u8&in seconds)
{
	this.SetGlobalMessage(text);
	this.set_u8("message_timer", seconds);
}

// See if the global message should be cleared
void resetTimedGlobalMessage(CRules@ this)
{
	u8 message_time = this.get_u8("message_timer");
	if (message_time > 0)
	{
		message_time--;
		
		if (message_time == 0)
			this.SetGlobalMessage("");
		
		this.set_u8("message_timer", message_time);
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
	if (this.isWarmup()) return;
	
	//have all players died?
	if (!isGameLost()) return;
	
	this.SetCurrentState(GAME_OVER);
	setTimedGlobalMessage(this, "Game over! All survivors perished! You lasted "+this.get_u8("day_number")+" days.", nextmap_seconds);
}

// Check if we lost the game
const bool isGameLost()
{
	bool noAlivePlayers = true;
	
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ ply = getPlayer(i);
		if (ply is null) continue;
		
		CBlob@ plyBlob = ply.getBlob();
		if (plyBlob !is null && !plyBlob.hasTag("undead") && !plyBlob.hasTag("dead"))
		{
			noAlivePlayers = false;
			break;
		}
	}
	
	return noAlivePlayers;
}
