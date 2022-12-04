// Punish players by forcing them to become zombies for the duration of their ban
// A better alternative to hard-bans, since players can still 'play' while being punished.

// this file MUST be called after Zombie_Respawning.as in gamemode.cfg to work fully

#define SERVER_ONLY;

#include "RespawnCommon.as";

const string FileName = "Zombie_SoftBans.cfg";

ConfigFile@ openBansConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/"+FileName))
	{
		warn("Creating soft bans config ../Cache/"+FileName);
		cfg.saveFile(FileName);
	}

	return cfg;
}

const bool isSoftBanned(CPlayer@ player, string&out playerKey, int&out time)
{
	ConfigFile@ cfg = openBansConfig();
	
	//check banned IP addresses
	const string IP = player.server_getIP();
	if (cfg.exists(IP+"_time_end"))
	{
		playerKey = IP;
		time = cfg.read_s32(IP+"_time_end");
		return true;
	}
	
	//check banned usernames
	const string Username = player.getUsername();
	if (cfg.exists(Username+"_time_end"))
	{
		playerKey = Username;
		time = cfg.read_s32(Username+"_time_end");
		return true;
	}
	
	return false;
}

void SoftBan(string&in playerKey, string&in description, const int&in time)
{
	ConfigFile@ cfg = openBansConfig();
	
	//ban by IP if available, set new player if online
	CPlayer@ player = getPlayerByUsername(playerKey);
	if (player !is null)
	{	
		description = "[ "+playerKey+" ] " + description;
		playerKey = player.server_getIP();
	}
	
	const bool isPermanentBan = time < 0;
	
	//add to ban file
	cfg.add_s32(playerKey+"_time_end", isPermanentBan ? -1 : Time() + time);
	cfg.add_string(playerKey+"_description", description);
	cfg.saveFile(FileName);
	
	error("\nSoft banned [ "+playerKey+" ] for"+(isPermanentBan ? "ever" : " "+time/60+" minutes")+"; "+description+"\n");
}

const bool RemoveSoftBan(CRules@ this, CPlayer@ player, const string&in playerKey, const int&in time)
{
	if (Time() >= time && time > -1)
	{
		ConfigFile@ cfg = openBansConfig();
		
		cfg.remove(playerKey+"_time_end");
		cfg.remove(playerKey+"_description");
		cfg.saveFile(FileName);
		
		if (player !is null)
		{
			//set player back to survivors
			player.server_setTeamNum(0);
			CBlob@ blob = player.getBlob();
			if (blob !is null)
			{
				if (blob.hasTag("undead") && blob.getBrain() !is null)
				{
					blob.server_SetPlayer(null);
					blob.getBrain().server_SetActive(true);
				}
				else
				{
					blob.server_Die();
				}
			}
			
			//remove player from queue
			string[]@ usernames;
			if (this.get("softban_spawn_queue", @usernames))
			{
				const int usernameIndex = usernames.find(player.getUsername());
				if (usernameIndex > -1) usernames.erase(usernameIndex);
			}
		}
		
		return true;
	}
	
	return false;
}

void SetUndead(CRules@ this, CPlayer@ player)
{
	Respawn[]@ respawns;
	if (!this.get("respawns", @respawns))
	{
		warn("SetUndead:: failed to access respawns!");
		return;
	}
	
	//remove any previous respawn
	const string username = player.getUsername();
	for (u8 i = 0; i < respawns.length; i++)
	{
		Respawn@ r = respawns[i];
		if (r.username != username) continue;
		respawns.erase(i);
		break;
	}
	
	player.server_setTeamNum(-2);
	CBlob@ blob = player.getBlob();
	if (blob !is null)
	{
		if (blob.hasTag("undead") && blob.getBrain() !is null)
		{
			blob.server_SetPlayer(null);
			blob.getBrain().server_SetActive(true);
		}
		else
		{
			blob.server_Die();
		}
	}
	
	//see if we can spawn as a wraith right now
	bool foundWraith = false;
	CBlob@[] wraiths;
	if (getBlobsByName("wraith", @wraiths))
	{
		for (u8 i = 0; i < wraiths.length; i++)
		{
			CBlob@ wraith = wraiths[i];
			if (wraith.getPlayer() is null)
			{
				wraith.server_SetPlayer(player);
				wraith.getBrain().server_SetActive(false);
				foundWraith = true;
				break;
			}
		}
	}
	
	//can't find a wraith? add player to queue
	if (!foundWraith)
	{
		string[]@ usernames;
		if (this.get("softban_spawn_queue", @usernames))
		{
			if (usernames.find(username) < 0)
			{
				usernames.push_back(username);
			}
		}
	}
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	//queued players become wraiths
	if (blob.getName() != "wraith") return;
	
	string[]@ usernames;
	if (!this.get("softban_spawn_queue", @usernames) || usernames.length <= 0) return;
	
	for (u8 i = 0; i < usernames.length; i++)
	{
		CPlayer@ player = getPlayerByUsername(usernames[i]);
		if (player !is null)
		{
			usernames.erase(i);
			blob.server_SetPlayer(player);
			blob.getBrain().server_SetActive(false);
			break;
		}
	}
}

void onInit(CRules@ this)
{
	string[] usernames;
	this.set("softban_spawn_queue", usernames);
}

void onRestart(CRules@ this)
{
	const u8 plyCount = getPlayerCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		string playerKey;
		int time;
		if (isSoftBanned(player, playerKey, time))
		{
			if (!RemoveSoftBan(this, player, playerKey, time))
			{
				SetUndead(this, player);
			}
		}
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	string playerKey;
	int time;
	if (isSoftBanned(player, playerKey, time))
	{
		if (!RemoveSoftBan(this, player, playerKey, time))
		{
			SetUndead(this, player);
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	string playerKey;
	int time;
	if (isSoftBanned(player, playerKey, time))
	{
		//upgrade username ban to IP if applicable
		if (playerKey == player.getUsername())
		{
			ConfigFile@ cfg = openBansConfig();
			
			const string IP = player.server_getIP();
			const string description = cfg.read_string(playerKey+"_description");
			
			cfg.remove(playerKey+"_time_end");
			cfg.remove(playerKey+"_description");
			cfg.add_s32(IP+"_time_end", time);
			cfg.add_string(IP+"_description", description);
			cfg.saveFile(FileName);
		}
		
		if (!RemoveSoftBan(this, player, playerKey, time))
		{
			SetUndead(this, player);
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_softban"))
	{
		string playerKey;
		string description;
		int time;
		if (!params.saferead_string(playerKey))
		{
			warn("server_soft_ban CMD:: failed to read playerKey!");
			return;
		}
		if (!params.saferead_string(description))
		{
			warn("server_soft_ban CMD:: failed to read description!");
			return;
		}
		if (!params.saferead_s32(time))
		{
			warn("server_soft_ban CMD:: failed to read time!");
			return;
		}
		
		SoftBan(playerKey, description, time);
		
		CPlayer@ player = getPlayerByUsername(playerKey);
		if (player !is null)
		{
			SetUndead(this, player);
		}
	}
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;
	
	if (sv_test || player.isMod() || player.getUsername() == "MrHobo")
	{
		return true;
	}
	
	//soft banned players are muted
	string playerKey;
	int time;
	if (isSoftBanned(player, playerKey, time))
	{
		return false;
	}
	
	return true;
}
