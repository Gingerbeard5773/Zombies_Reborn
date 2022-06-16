//Zombie fortress scoreboard information

#define SERVER_ONLY

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		string[] name = map.getMapName().split('/'); //Official server maps seem to show up as
		string mapName = name[name.length - 1]; //``Maps/CTF/MapNameHere.png`` while using this instead of just the .png
		mapName = getFilenameWithoutExtension(mapName); // Remove extension from the filename if it exists

		this.set_string("map_name", mapName);
		this.Sync("map_name", true); //734528625 HASH
	}
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
	}
}
