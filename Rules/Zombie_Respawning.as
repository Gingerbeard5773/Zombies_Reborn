//Zombie Fortress player respawning

#define SERVER_ONLY

const u32 spawn_seconds = 5; //minimum amount of seconds players have to wait to respawn

u32 spawn_leniency = 40;   //players can insta-respawn for this many seconds after dawn comes
u16 undead_leniency = 10;  //amount of zombies allowed before we disable full day insta respawns

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
		spawn_leniency = cfg.exists("spawn_leniency") ? cfg.read_u32("spawn_leniency") : 40;
		undead_leniency = cfg.exists("undead_leniency") ? cfg.read_u16("undead_leniency") : 10;
	}

	dictionary respawns;
	this.set("respawns", @respawns);

	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getTeamNum() == 3) continue;

		respawns.set(player.getUsername(), 0);
	}

	this.set_u32("client respawn time", 0);
	this.Sync("client respawn time", true);
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

	dictionary@ respawns;
	if (!this.get("respawns", @respawns)) { error("Failed to attain respawns! :: "+getCurrentScriptName()); return; }

	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getBlob() !is null || player.getTeamNum() == 3) continue;

		const string username = player.getUsername();
		if (!respawns.exists(username))
		{
			SetPlayerRespawn(this, player, respawns);
			continue;
		}

		u32 player_respawn_time;
		respawns.get(username, player_respawn_time);

		if (canRespawnQuick(this, timeElapsed, map) && player_respawn_time - dawn_respawn_time <= 30)
		{
			const u32 respawn_time = spawn_seconds*30 + gameTime;
			respawns.set(username, respawn_time);

			this.set_u32("client respawn time", respawn_time);
			this.SyncToPlayer("client respawn time", player);
		}

		if (gameTime >= player_respawn_time)
		{
			spawnPlayer(this, player);
		}
	}
}

void SetPlayerRespawn(CRules@ this, CPlayer@ player, dictionary@ respawns)
{
	if (player.getTeamNum() == 3) return;

	const u32 gameTime = getGameTime();
	const u32 day_cycle = this.daycycle_speed * 60;
	const u32 timeElapsed = (gameTime / 30) % day_cycle;
	const int timeTillDawn = (day_cycle - timeElapsed) * 30;

	u32 respawn_time = canRespawnQuick(this, timeElapsed, getMap()) ? spawn_seconds*30 : timeTillDawn;
	respawn_time += gameTime;

	respawns.set(player.getUsername(), respawn_time);

	this.set_u32("client respawn time", respawn_time);
	this.SyncToPlayer("client respawn time", player);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	dictionary@ respawns;
	this.get("respawns", @respawns);

	SetPlayerRespawn(this, victim, respawns);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	dictionary@ respawns;
	this.get("respawns", @respawns);

	const string username = player.getUsername();
	if (respawns.exists(username))
	{
		respawns.delete(username);
	}
}

bool canRespawnQuick(CRules@ this, const u32&in timeElapsed, CMap@ map)
{
	if (this.get_u16("day_number") < 2)
		return true;
	if (timeElapsed <= spawn_leniency)
		return true;
	if (this.get_u16("undead count") <= undead_leniency && map.getDayTime() > 0.2f && map.getDayTime() < 0.7f)
		return true;

	return false;
}

void spawnPlayer(CRules@ this, CPlayer@ player)
{
	//remove previous player's blob
	CBlob@ blob = player.getBlob();
	if (blob !is null)
	{
		if (!blob.hasTag("dead")) return;

		blob.server_SetPlayer(null);
		blob.server_Die();
	}

	CBlob@ respawn_point = getBlobByNetworkID(player.getSpawnPoint());
	Vec2f spawnPos = respawn_point !is null ? respawn_point.getPosition() : getParachuteSpawnLocation();

	CBlob@ newBlob = server_CreateBlob("builder", 0, spawnPos);
	newBlob.server_SetPlayer(player);

	//give the blob a parachute if spawning at roof
	if (this.hasCommandID("client_give_parachute") && spawnPos.y <= 16)
	{
		newBlob.AddScript("ParachuteEffect.as");

		CBitStream stream;
		stream.write_netid(newBlob.getNetworkID());
		this.SendCommand(this.getCommandID("client_give_parachute"), stream);
	}
}

Vec2f getParachuteSpawnLocation()
{
	CMap@ map = getMap();
	Vec2f spawnPos = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);
	return spawnPos;
}
