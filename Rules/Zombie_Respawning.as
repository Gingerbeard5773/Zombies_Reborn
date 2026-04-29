//Zombie Fortress player respawning

#define SERVER_ONLY

#include "GetSurvivors.as"
#include "UndeadTeam.as"

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

	const u8 player_count = getPlayerCount();
	for (u8 i = 0; i < player_count; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getTeamNum() != 0) continue;

		respawns.set(player.getUsername(), 0);
	}

	this.set_u32("client respawn time", 0);
	this.Sync("client respawn time", true);
}

void onTick(CRules@ this)
{
	const u32 gametime = getGameTime();
	if (gametime % 30 != 0 || this.isGameOver()) return;

	dictionary@ respawns;
	if (!this.get("respawns", @respawns)) { error("Failed to attain respawns! :: "+getCurrentScriptName()); return; }

	int time_till_dawn, time_since_dawn;
	getDayTimeElapsed(this, time_till_dawn, time_since_dawn);

	const bool fast_respawn = canFastRespawn(this, time_since_dawn);

	const u8 player_count = getPlayerCount();
	for (u8 i = 0; i < player_count; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getBlob() !is null || player.getTeamNum() != 0) continue;

		const string username = player.getUsername();

		// give the player a respawn if they dont have one already
		if (!respawns.exists(username))
		{
			SetPlayerRespawn(this, player);
			continue;
		}

		u32 player_respawn_time;
		respawns.get(username, player_respawn_time);

		// spawn our player if we reached our respawn time
		if (gametime >= player_respawn_time)
		{
			SpawnPlayer(this, player);
			continue;
		}

		const u32 fast_respawn_time = spawn_seconds * 30 + gametime;
		if (player_respawn_time <= fast_respawn_time) continue;

		// reset our respawn time to be short if fast respawns are available
		if (fast_respawn)
		{
			SetRespawn(this, player, respawns, fast_respawn_time);
			continue;
		}

		// readjust respawn if the daycycle speed changed
		if (!fast_respawn && Maths::Abs(player_respawn_time - (gametime + time_till_dawn)) > 10 * 30)
		{
			SetPlayerRespawn(this, player);
		}
	}
}

void getDayTimeElapsed(CRules@ this, int&out time_till_dawn, int&out time_since_dawn)
{
	const f32 day_time = getMap().getDayTime();
	const f32 day_start = this.daycycle_start;
	const u32 day_cycle = this.daycycle_speed * 60 * 30;

	// time till dawn
	const f32 till = Maths::FMod(day_start - day_time + 1.0f, 1.0f);
	time_till_dawn = till * day_cycle;

	// time since dawn
	const f32 since = Maths::FMod(day_time - day_start + 1.0f, 1.0f);
	time_since_dawn = since * day_cycle;
}

bool canFastRespawn(CRules@ this, const u32&in time_since_dawn)
{
	// within warmup period
	if (this.get_u16("day_number") < 2) return true;

	// within the time leniency period at dawn
	if (time_since_dawn <= spawn_leniency * 30) return true;

	// map is cleared of zombies during day time
	const bool day = getMap().getDayTime() > 0.2f && getMap().getDayTime() < 0.75f;
	if (this.get_u16("undead count") <= undead_leniency && day) return true;

	return false;
}

void SetPlayerRespawn(CRules@ this, CPlayer@ player)
{
	if (player.getTeamNum() != 0) return;

	dictionary@ respawns;
	if (!this.get("respawns", @respawns)) return;

	int time_till_dawn, time_since_dawn;
	getDayTimeElapsed(this, time_till_dawn, time_since_dawn);

	const bool fast_respawn = canFastRespawn(this, time_since_dawn);
	const u32 respawn_time = (fast_respawn ? spawn_seconds * 30 : time_till_dawn) + getGameTime();

	SetRespawn(this, player, respawns, respawn_time);
}

void SetRespawn(CRules@ this, CPlayer@ player, dictionary@ respawns, const u32&in respawn_time)
{
	respawns.set(player.getUsername(), respawn_time);

	this.set_u32("client respawn time", respawn_time);
	this.SyncToPlayer("client respawn time", player);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	SetPlayerRespawn(this, victim);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	SetPlayerRespawn(this, player);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	dictionary@ respawns;
	if (!this.get("respawns", @respawns)) return;

	const string username = player.getUsername();
	if (respawns.exists(username))
	{
		respawns.delete(username);
	}
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
	if (isUndeadTeam(player)) return;

	player.server_setTeamNum(newteam);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	// do a fast respawn if there is no survivor players.
	// this is done in case all players left the server, and we just joined into an empty server
	CPlayer@[] players; getSurvivors(@players, player);
	if (players.length > 0) return;

	dictionary@ respawns;
	if (!this.get("respawns", @respawns)) return;

	const u32 respawn_time = 90 + getGameTime();
	SetRespawn(this, player, respawns, respawn_time);
}

void SpawnPlayer(CRules@ this, CPlayer@ player)
{
	// remove previous player's blob
	CBlob@ blob = player.getBlob();
	if (blob !is null)
	{
		if (!blob.hasTag("dead")) return;

		blob.server_SetPlayer(null);
		blob.server_Die();
	}

	CBlob@ respawn_point = getBlobByNetworkID(player.getSpawnPoint());
	Vec2f spawn = respawn_point !is null ? respawn_point.getPosition() : getParachuteSpawnLocation();

	CBlob@ new_blob = server_CreateBlob("builder", 0, spawn);
	new_blob.server_SetPlayer(player);

	// give the new blob a parachute if spawning in the sky
	if (this.hasCommandID("client_give_parachute") && respawn_point is null)
	{
		new_blob.AddScript("ParachuteEffect.as");

		CBitStream stream;
		stream.write_netid(new_blob.getNetworkID());
		this.SendCommand(this.getCommandID("client_give_parachute"), stream);
	}
}

Vec2f getParachuteSpawnLocation()
{
	CMap@ map = getMap();
	const f32 spawnheight = 500.0f;
	Vec2f spawn = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);

	f32 closest = 99999.0f; 

	Vec2f[] ends = { Vec2f(0, spawnheight), Vec2f(spawnheight, spawnheight), Vec2f(-spawnheight, spawnheight) };
	for (u8 i = 0; i < 3; i++)
	{
		Vec2f end = spawn + ends[i];
		map.rayCastSolid(spawn, end, end);

		if (end.y < closest)
		{
			closest = end.y;
		}
	}

	spawn.y = closest > spawnheight ? 0 : closest - spawnheight;

	return spawn;
}
