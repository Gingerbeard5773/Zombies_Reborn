// Punish players by forcing them to become zombies for the duration of their ban
// A better alternative to hard-bans, since players can still 'play' while being punished.
// Lets griefers grief legally i suppose? >:)

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

const bool isSoftBanned(CPlayer@ player)
{
	string playerKey;
	int time;
	return isSoftBanned(player, playerKey, time);
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
	const string username = player.getUsername();

	player.server_setTeamNum(3);
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
	
	//see if we can spawn as an undead right now
	bool foundUndead = false;
	CBlob@[] undeads;
	CBlob@[] available_undeads;
	if (getBlobsByTag("undead", @undeads))
	{
		for (u16 i = 0; i < undeads.length; i++)
		{
			CBlob@ undead = undeads[i];
			if (undead.getPlayer() !is null) continue;
			
			const string name = undead.getName();
			if (name == "greg" || name == "skelepede" || name == "wraith") continue;

			available_undeads.push_back(undead);
		}
	}
	
	if (available_undeads.length > 0)
	{
		CBlob@ undead = available_undeads[XORRandom(available_undeads.length)];
		undead.server_SetPlayer(player);
		undead.getBrain().server_SetActive(false);
		foundUndead = true;
	}
	
	//can't find an undead? add player to queue
	if (!foundUndead)
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
