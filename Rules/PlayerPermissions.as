// Player permissions

void getPermissions(CPlayer@ player, bool&out isAdmin, bool&out isSuperAdmin)
{
	const string[] isCool = { "MrHobo" };

	CSecurity@ sec = getSecurity();
	const string role = sec.getPlayerSeclev(player).getName();
	const bool isLocalhost = isServer() && isClient();
	isSuperAdmin = isCool.find(player.getUsername()) != -1 || isLocalhost || player.isMod() || player.isRCON() || role == "Super Admin";
	isAdmin = isSuperAdmin || role == "Admin" || sec.checkAccess_Command(player, "ban");
}
