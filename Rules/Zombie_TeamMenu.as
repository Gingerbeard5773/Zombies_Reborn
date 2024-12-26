// Zombie Fortress team menu

#include "Zombie_Translation.as";
#include "Zombie_GlobalMessagesCommon.as";
#include "GetSurvivors.as";

const Vec2f BUTTON_SIZE(4, 4);

void onInit(CRules@ this)
{
	AddIconToken("$BLUE_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 0);
}

void Callback_PickTeams(CBitStream@ params)
{
	u8 team;
	if (!params.saferead_u8(team)) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	player.client_ChangeTeam(team);
	getHUD().ClearMenus();
}

void Callback_PickNone(CBitStream@ params)
{
	getHUD().ClearMenus();
}

void ShowTeamMenu(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	getHUD().ClearMenus(true);
	
	const u8 team = player.getTeamNum();

	//dont switch teams if we are the last survivor
	CPlayer@[] players;
	getSurvivors(@players, player);
	if (team == 0 && players.length == 0) return;

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, BUTTON_SIZE, "Change team");
	if (menu is null) return;

	CBitStream exitParams;
	menu.AddKeyCallback(KEY_ESCAPE, "TeamMenu.as", "Callback_PickNone", exitParams);
	menu.SetDefaultCallback("TeamMenu.as", "Callback_PickNone", exitParams);

	CBitStream params;
	
	if (team == 0)
	{
		params.write_u8(this.getSpectatorTeamNum());
		CGridButton@ button2 = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), "TeamMenu.as", "Callback_PickTeams", BUTTON_SIZE, params);
	}
	else
	{
		params.write_u8(0);
		CGridButton@ button =  menu.AddButton("$BLUE_TEAM$", Translate::Survivors, "TeamMenu.as", "Callback_PickTeams", BUTTON_SIZE, params);
	}
}
