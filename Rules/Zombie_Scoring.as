//Zombie fortress scoreboard and statistics information

#define SERVER_ONLY

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();

	string[] name = map.getMapName().split('/'); //Official server maps seem to show up as
	string mapName = name[name.length - 1]; //``Maps/CTF/MapNameHere.png`` while using this instead of just the .png
	mapName = getFilenameWithoutExtension(mapName); // Remove extension from the filename if it exists
	
	if (map.exists("map seed"))
	{
		mapName = map.get_s32("map seed") + "";
	}

	this.set_string("map_name", mapName);
	this.Sync("map_name", true);
	
	//reset player scores
	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		player.setScore(0);
		player.setDeaths(0);
		player.setKills(0);
		player.setAssists(0);
	}
	
	//reset server scores
	this.set_u32("score_undead_killed_total", 0);
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (this.isGameOver() || blob is null) return;
	
	CPlayer@ victim = blob.getPlayer();
	if (victim !is null)
	{
		victim.setDeaths(victim.getDeaths() + 1);
	}
	
	//killing zombies gives kills
	if (blob.hasTag("undead"))
	{
		CPlayer@ hitterPly = blob.getPlayerOfRecentDamage();
		if (hitterPly !is null)
		{
			hitterPly.setKills(hitterPly.getKills() + 1);
		}
		this.add_u32("score_undead_killed_total", 1);
	}
}
