// Undead Team funcs

u8 getUndeadTeam()
{
	return 3;
}

bool isUndeadTeam(const u8&in team)
{
	return team == getUndeadTeam();
}

bool isUndeadTeam(CBlob@ blob)
{
	return isUndeadTeam(blob.getTeamNum());
}

bool isUndeadTeam(CPlayer@ player)
{
	return isUndeadTeam(player.getTeamNum());
}
