#include "CTF_PopulateSpawnList.as"
#include "Zombie_Translation.as"

#define CLIENT_ONLY

const int BUTTON_SIZE = 2;
u16 LAST_PICK = 0;
u16 RESPAWNS_COUNT = 0;
bool REQUESTED_SPAWN = false;
bool SHOW_MENU = true;

CGridMenu@ getRespawnMenu()
{
	return getGridMenuByName(getTranslatedString("Pick spawn point"));
}

void RemoveRespawnMenu()
{
	CGridMenu@ menu = getRespawnMenu();
	if (menu !is null)
		menu.kill = true;
}

void BuildRespawnMenu(CRules@ this, CPlayer@ player, CBlob@[] respawns)
{
	RemoveRespawnMenu();

	if (player.getTeamNum() == this.getSpectatorTeamNum()) return;

	if (!REQUESTED_SPAWN)
	{
		REQUESTED_SPAWN = true;
		player.client_RequestSpawn(LAST_PICK); // spawn even without pick
	}

	// if there are no options then just respawn
	if (respawns.length <= 0)
	{
		LAST_PICK = 0;
		return;
	}

	SortByPosition(@respawns);

	// build menu for spawns
	const Vec2f menupos = getDriver().getScreenCenterPos() + Vec2f(0.0f, getDriver().getScreenHeight() / 2.0f - BUTTON_SIZE - 46.0f);
	CGridMenu@ menu = CreateGridMenu(menupos, null, Vec2f((respawns.length + 1) * BUTTON_SIZE, BUTTON_SIZE), getTranslatedString("Pick spawn point"));
	if (menu is null) return;

	menu.modal = true;
	menu.deleteAfterClick = false;

	CBitStream stream;
	for (uint i = 0; i < respawns.length; i++)
	{
		CBlob@ respawn = respawns[i];
		stream.ResetBitIndex();
		stream.write_u16(respawn.getNetworkID());
		const string msg = getTranslatedString("Spawn at {ITEM}").replace("{ITEM}", getTranslatedString(respawn.getInventoryName()));
		CGridButton@ button = menu.AddButton("$" + respawn.getName() + "$", msg, "Zombie_PickSpawn.as", "Callback_PickSpawn", Vec2f(BUTTON_SIZE, BUTTON_SIZE), stream);
		if (button !is null)
		{
			button.selectOneOnClick = true;

			if (LAST_PICK == respawn.getNetworkID())
			{
				button.SetSelected(1);
			}
		}
	}

	//parachute option
	stream.ResetBitIndex();
	stream.write_u16(0);
	CGridButton@ pbutton = menu.AddButton("$parachute$", Translate::Respawn3, "Zombie_PickSpawn.as", "Callback_PickSpawn", Vec2f(BUTTON_SIZE, BUTTON_SIZE), stream);
	if (pbutton !is null)
	{
		pbutton.selectOneOnClick = true;

		if (LAST_PICK == 0)
		{
			pbutton.SetSelected(1);
		}
	}
}

void onTick(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null || !player.isMyPlayer()) return;

	if (SHOW_MENU)
	{
		if (this.isGameOver())
		{
			RemoveRespawnMenu();
			SHOW_MENU = false;
		}

		CBlob@[] respawns;
		PopulateSpawnList(@respawns, player.getTeamNum());
		if (RESPAWNS_COUNT != respawns.length || getRespawnMenu() is null)
		{
			RESPAWNS_COUNT = respawns.length;
			BuildRespawnMenu(this, player, respawns);
		}
	}
}

// setup the menu when our player dies
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null && victim.isMyPlayer() && !this.isGameOver())
	{
		SHOW_MENU = true;
		RESPAWNS_COUNT = -1;
	}
}

// turn off the menu when we spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null && player.isMyPlayer())
	{
		getHUD().ClearMenus(true);

		REQUESTED_SPAWN = false;
		SHOW_MENU = false;
	}
}

void Callback_PickSpawn(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	u16 pick;
	if (!params.saferead_u16(pick)) return;

	LAST_PICK = pick; 

	if (player.getTeamNum() == getRules().getSpectatorTeamNum())
	{
		getHUD().ClearMenus(true);
	}
	else
	{
		player.client_RequestSpawn(pick);
	}
}

void SortByPosition(CBlob@[]@ spawns)
{
	// Selection Sort
	const u16 spawns_length = spawns.length;
	for (u16 i = 0; i < spawns_length; i++)
	{
		u16 minIndex = i;

		// Find the index of the minimum element
		for (u16 j = i + 1; j < spawns_length; j++)
		{
			if (spawns[j].getPosition().x < spawns[minIndex].getPosition().x)
			{
				minIndex = j;
			}
		}

		// Swap if i-th element not already smallest
		if (minIndex > i)
		{
			CBlob@ temp = spawns[i];
			@spawns[i] = spawns[minIndex];
			@spawns[minIndex] = temp;
		}
	}
}
