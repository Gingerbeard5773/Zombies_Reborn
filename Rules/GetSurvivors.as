// Functions for getting survivors

CBlob@[] getSurvivors()
{
	CPlayer@[] survivor_players;
	CBlob@[] survivors = getSurvivors(survivor_players);
	return survivors;
}

CBlob@[] getSurvivors(CPlayer@[]@ survivor_players, CPlayer@ excluded = null)
{
	CBlob@[] survivors;
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player.getTeamNum() != 0 || player is excluded) continue;

		survivor_players.push_back(player);

		CBlob@ blob = player.getBlob();
		if (blob !is null && !blob.hasTag("undead") && !blob.hasTag("dead"))
		{
			survivors.push_back(blob);
		}
	}

	return survivors;
}
