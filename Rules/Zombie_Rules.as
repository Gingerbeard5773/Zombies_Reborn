// Zombie Fortress generic rules

#define SERVER_ONLY

#include "Zombie_GlobalMessagesCommon.as"
#include "GetSurvivors.as"

const u8 nextmap_seconds = 15;
u8 seconds_till_nextmap = nextmap_seconds;

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	seconds_till_nextmap = nextmap_seconds;
	this.SetCurrentState(GAME);
}

void onTick(CRules@ this)
{
	if (this.getCurrentState() != GAME_OVER) return;

	if (getGameTime() % getTicksASecond() != 0) return;

	if (seconds_till_nextmap-- == 0)
	{
		LoadNextMap();
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	CheckGameOver(this, victim);
}

void CheckGameOver(CRules@ this, CPlayer@ player)
{
	// End the game if all survivors are dead

	if (this.getCurrentState() == GAME_OVER) return;

	const u16 dayNumber = this.get_u16("day_number");
	if (dayNumber < 2) return;

	if (getSurvivors(player).length > 0) return;

	this.SetCurrentState(GAME_OVER);

	string[] inputs = {dayNumber+""};
	server_SendGlobalMessage(this, "GameOver", nextmap_seconds, inputs);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	AntiSpectatorCamping(player);
}

void AntiSpectatorCamping(CPlayer@ player)
{
	// Force at least one player to be a survivor at all times

	CPlayer@[] players; getSurvivors(@players, player);
	if (players.length > 0) return;

	CPlayer@[] spectators = getSpectators(player);
	if (spectators.length <= 0) return;

	CPlayer@ random_player = spectators[XORRandom(spectators.length)];
	random_player.server_setTeamNum(0);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	// Set new player to survivors

	player.server_setTeamNum(0);
}
