//Zombie Fortress player respawning

#define SERVER_ONLY

const string startClass = "builder";  //the class that players will spawn as
const u32 spawnTimeLeniency = 30;     //players can insta-respawn for this many seconds after dawn comes
const u32 spawnTimeMargin = 8;        //max amount of random seconds we can give to respawns

shared class Respawn
{
	string username;
	u32 timeStarted;

	Respawn(const string _username, const u32 _timeStarted)
	{
		username = _username;
		timeStarted = _timeStarted;
	}
};

void onInit(CRules@ this)
{
	Respawn[] respawns;
	this.set("respawns", respawns);
}

void onRestart(CRules@ this)
{
	this.clear("respawns");
	
	const u32 gameTime = getGameTime();
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		Respawn r(player.getUsername(), gameTime);
		this.push("respawns", r);
		syncRespawnTime(this, player, gameTime);
	}
}

void onTick(CRules@ this)
{
	const u32 gametime = getGameTime();
	if (gametime % 30 == 0 && !this.isGameOver())
	{
		Respawn[]@ respawns;
		if (!this.get("respawns", @respawns)) return;
		
		for (u8 i = 0; i < respawns.length; i++)
		{
			Respawn@ r = respawns[i];
			if (r.timeStarted == 0 || r.timeStarted <= gametime)
			{
				spawnPlayer(this, getPlayerByUsername(r.username));
				respawns.erase(i);
				i = 0;
			}
		}
	}
}


void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded(this, player.getUsername()))
	{
		const u32 gametime = getGameTime();
		const u32 day_cycle = this.daycycle_speed * 60;
		
		const u32 timeElapsed = (gametime / getTicksASecond()) % day_cycle;
		const s32 timeTillDawn = (day_cycle - timeElapsed + XORRandom(spawnTimeMargin)) * getTicksASecond();
		
		const bool skipWait = timeElapsed <= spawnTimeLeniency || this.isWarmup();
		const s32 timeTillRespawn = skipWait ? 0 : timeTillDawn;
		
		Respawn r(player.getUsername(), timeTillRespawn + gametime);
		this.push("respawns", r);
		syncRespawnTime(this, player, timeTillRespawn + gametime);
	}
}

const bool isRespawnAdded(CRules@ this, const string&in username)
{
	Respawn[]@ respawns;
	if (this.get("respawns", @respawns))
	{
		const u8 respawnLength = respawns.length;
		for (u8 i = 0; i < respawnLength; i++)
		{
			Respawn@ r = respawns[i];
			if (r.username == username)
				return true;
		}
	}
	return false;
}

CBlob@ spawnPlayer(CRules@ this, CPlayer@ player)
{
	if (player !is null)
	{
		//remove previous players blob
		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		CBlob@ newBlob = server_CreateBlob(startClass, 0, getSpawnLocation());
		newBlob.server_SetPlayer(player);
		
		if (this.hasCommandID("give_parachute"))
		{
			CBitStream bs;
			bs.write_netid(newBlob.getNetworkID());
			this.SendCommand(this.getCommandID("give_parachute"), bs);
		}
		
		return newBlob;
	}

	return null;
}

Vec2f getSpawnLocation()
{
	const Vec2f dim = getMap().getMapDimensions();
	return Vec2f(XORRandom(dim.x), 0);
}

void syncRespawnTime(CRules@ this, CPlayer@ player, const u32&in time)
{
	this.set_u32("respawn time", time);
	this.SyncToPlayer("respawn time", player);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("remove respawn"))
	{
		const string username = params.read_string();
		
		Respawn[]@ respawns;
		if (!this.get("respawns", @respawns)) return;
		
		for (u8 i = 0; i < respawns.length; i++)
		{
			Respawn@ r = respawns[i];
			if (r.username == username)
			{
				respawns.erase(i);
				break;
			}
		}
	}
}
