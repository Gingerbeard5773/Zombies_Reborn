// Functions for getting survivors

CBlob@[] getSurvivors(CPlayer@ excluded = null)
{
	CPlayer@[] survivor_players;
	CBlob@[] survivors = getSurvivors(survivor_players, excluded);
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

CPlayer@[] getSpectators(CPlayer@ excluded = null)
{
	CPlayer@[] spectator_players;
	const u8 spectator_team = getRules().getSpectatorTeamNum();
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null || player is excluded) continue;

		if (player.getTeamNum() == spectator_team)
		{
			spectator_players.push_back(player);
		}
	}
	return spectator_players;
}
