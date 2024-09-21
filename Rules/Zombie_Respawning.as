//Zombie Fortress player respawning

#define SERVER_ONLY

const string startClass = "builder";  //the class that players will spawn as
const u32 spawnTimeLeniency = 30;     //players can insta-respawn for this many seconds after dawn comes
const u32 spawnTimeSeconds = 5;       //respawn duration during insta-respawn seconds
const u16 dayRespawnUndeadMax = 5;    //amount of zombies allowed before we disable full day insta respawns

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
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getTeamNum() == 200) continue;
		
		this.set_u32(player.getUsername()+" respawn time", 0);
	}
}

void onTick(CRules@ this)
{
	const u32 gameTime = getGameTime();
	if (gameTime % 30 != 0 || this.isGameOver()) return;
	
	CMap@ map = getMap();
	const u32 day_cycle = this.daycycle_speed * 60;
	const u32 timeElapsed = (gameTime / 30) % day_cycle;
	const int timeTillDawn = (day_cycle - timeElapsed) * 30;
	const u32 dawn_respawn_time = timeTillDawn + gameTime;

	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getBlob() !is null || player.getTeamNum() == 200) continue;

		const u32 player_respawn_time = this.get_u32(player.getUsername()+" respawn time");

		if (canRespawnQuick(this, timeElapsed, map) && player_respawn_time - dawn_respawn_time <= 30)
		{
			this.set_u32(player.getUsername()+" respawn time", spawnTimeSeconds*30 + gameTime);
			this.SyncToPlayer(player.getUsername()+" respawn time", player);
		}
		
		if (gameTime >= player_respawn_time)
		{
			spawnPlayer(this, player);
		}
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	if (victim.getTeamNum() == 200) return;

	const u32 gameTime = getGameTime();
	const u32 day_cycle = this.daycycle_speed * 60;
	const u32 timeElapsed = (gameTime / 30) % day_cycle;
	const int timeTillDawn = (day_cycle - timeElapsed) * 30;
	
	const u32 respawn_time = canRespawnQuick(this, timeElapsed, getMap()) ? spawnTimeSeconds*30 : timeTillDawn;

	this.set_u32(victim.getUsername()+" respawn time", respawn_time + gameTime);
	this.SyncToPlayer(victim.getUsername()+" respawn time", victim);
}

bool canRespawnQuick(CRules@ this, const u32&in timeElapsed, CMap@ map)
{
	if (this.get_u16("day_number") < 2)
		return true;
	if (timeElapsed <= spawnTimeLeniency)
		return true;
	if (this.get_u16("undead count") <= dayRespawnUndeadMax && map.getDayTime() > 0.2f && map.getDayTime() < 0.7f)
		return true;

	return false;
}

CBlob@ spawnPlayer(CRules@ this, CPlayer@ player)
{
	if (player is null) return null;

	//remove previous players blob
	CBlob@ blob = player.getBlob();
	if (blob !is null)
	{
		if (!blob.hasTag("dead")) return blob;
		
		blob.server_SetPlayer(null);
		blob.server_Die();
	}

	CBlob@ respawn_point = getBlobByNetworkID(player.getSpawnPoint());
	Vec2f spawnPos = respawn_point !is null ? respawn_point.getPosition() : getParachuteSpawnLocation();

	CBlob@ newBlob = server_CreateBlob(startClass, 0, spawnPos);
	newBlob.server_SetPlayer(player);
	
	//give the blob a parachute if spawning at roof
	if (this.hasCommandID("client_give_parachute") && spawnPos.y <= 16)
	{
		newBlob.AddScript("ParachuteEffect.as");

		CBitStream stream;
		stream.write_netid(newBlob.getNetworkID());
		this.SendCommand(this.getCommandID("client_give_parachute"), stream);
	}
	
	return newBlob;
}

Vec2f getParachuteSpawnLocation()
{
	CMap@ map = getMap();
	Vec2f spawnPos = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);
	return spawnPos;
}
