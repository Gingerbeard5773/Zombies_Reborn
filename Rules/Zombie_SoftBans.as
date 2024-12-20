// Punish players by forcing them to become zombies for the duration of their ban
// A better alternative to hard-bans, since players can still 'play' while being punished.

// this file MUST be called after Zombie_Respawning.as in gamemode.cfg to work fully

#define SERVER_ONLY;

#include "Zombie_SoftBansCommon.as";

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	//queued players become undeads
	if (!blob.hasTag("undead")) return;

	if (blob.getName() == "greg") return;

	string[]@ usernames;
	if (!this.get("softban_spawn_queue", @usernames) || usernames.length <= 0) return;
	
	for (u8 i = 0; i < usernames.length; i++)
	{
		CPlayer@ player = getPlayerByUsername(usernames[i]);
		if (player is null) continue;

		usernames.erase(i);
		blob.server_SetPlayer(player);
		blob.getBrain().server_SetActive(false);
		break;
	}
}

void onInit(CRules@ this)
{
	string[] usernames;
	this.set("softban_spawn_queue", usernames);
}

void onRestart(CRules@ this)
{
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		onPlayerRequestSpawn(this, player);
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

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
	if (player.getTeamNum() != 3) return;

	string playerKey;
	int time;
	if (isSoftBanned(player, playerKey, time))
	{
		if (RemoveSoftBan(this, player, playerKey, time))
		{
			player.server_setTeamNum(newteam);
		}
	}
}
