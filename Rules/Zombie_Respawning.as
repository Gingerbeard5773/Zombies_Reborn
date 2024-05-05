//Zombie Fortress player respawning

#define SERVER_ONLY

#include "RespawnCommon.as";

const string startClass = "builder";  //the class that players will spawn as
const u32 spawnTimeLeniency = 30;     //players can insta-respawn for this many seconds after dawn comes
const u32 spawnTimeMargin = 8;        //max amount of random seconds we can give to respawns
const u32 spawnTimeSeconds = 3;       //respawn duration during insta-respawn seconds
const u16 dayRespawnUndeadMax = 5;    //amount of zombies allowed before we disable full day insta respawns

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
		addRespawn(this, getPlayer(i), gameTime);
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
			if (r.timeStarted > gametime) continue;
			
			spawnPlayer(this, getPlayerByUsername(r.username));
			respawns.erase(i);
			i = 0;
		}
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	//recheck if we can skip wait times
	if (!blob.hasTag("undead") || this.get_u16("undead count") > dayRespawnUndeadMax) return;
	
	Respawn[]@ respawns;
	if (!this.get("respawns", @respawns) || respawns.length <= 0) return;
	
	const int timeTillRespawn = getTimeTillRespawn(this);
	if (timeTillRespawn > spawnTimeSeconds * getTicksASecond() + getGameTime()) return;
	
	const u8 respawnLength = respawns.length;
	for (u8 i = 0; i < respawnLength; i++)
	{
		Respawn@ r = respawns[i];
		r.timeStarted = timeTillRespawn;
		syncRespawnTime(this, getPlayerByUsername(r.username), timeTillRespawn);
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!isRespawnAdded(this, player.getUsername()))
	{
		addRespawn(this, player, getTimeTillRespawn(this));
	}
}

void addRespawn(CRules@ this, CPlayer@ player, const int&in timeTillRespawn)
{
	Respawn r(player.getUsername(), timeTillRespawn);
	this.push("respawns", r);
	syncRespawnTime(this, player, timeTillRespawn);
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

const int getTimeTillRespawn(CRules@ this)
{
	const u32 gametime = getGameTime();
	const u32 day_cycle = this.daycycle_speed * 60;
	
	const u32 timeElapsed = (gametime / getTicksASecond()) % day_cycle;
	const int timeTillDawn = (day_cycle - timeElapsed + XORRandom(spawnTimeMargin)) * getTicksASecond();
	
	const bool skipWait = skipRespawnWait(this, timeElapsed);
	const int timeTillRespawn = skipWait ? spawnTimeSeconds * getTicksASecond() : timeTillDawn;
	
	return timeTillRespawn + gametime;
}

const bool skipRespawnWait(CRules@ this, const u32&in timeElapsed)
{
	CMap@ map = getMap();
	return
		(this.isWarmup()) ||
		(timeElapsed <= spawnTimeLeniency) ||
		(this.get_u16("undead count") <= dayRespawnUndeadMax && map.getDayTime() > 0.2f && map.getDayTime() < 0.7f);
}

CBlob@ spawnPlayer(CRules@ this, CPlayer@ player)
{
	if (player !is null)
	{
		//remove previous players blob
		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			if (!blob.hasTag("dead"))
				return blob;
			
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		Vec2f spawnPos = getSpawnLocation();
		CBlob@ newBlob = server_CreateBlob(startClass, 0, spawnPos);
		newBlob.server_SetPlayer(player);
		
		//give the blob a parachute if spawning at roof
		if (this.hasCommandID("client_give_parachute") && spawnPos.y <= 16)
		{
			newBlob.AddScript("ParachuteEffect.as");

			CBitStream bs;
			bs.write_netid(newBlob.getNetworkID());
			this.SendCommand(this.getCommandID("client_give_parachute"), bs);
		}
		
		return newBlob;
	}

	return null;
}

Vec2f getSpawnLocation()
{
	CMap@ map = getMap();
	Vec2f spawnPos = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);
	if (map.isTileSolid(map.getTile(spawnPos)))
	{
		Vec2f[] spawns;
		if (map.getMarkers("zombie_spawn", spawns))
		{
			return spawns[XORRandom(spawns.length)];
		}
	}
	return spawnPos;
}

void syncRespawnTime(CRules@ this, CPlayer@ player, const u32&in time)
{
	this.set_u32("respawn time", time);
	this.SyncToPlayer("respawn time", player);
}
