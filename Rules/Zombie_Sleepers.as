//Allow reconnecting players to get back into the game fast

#define SERVER_ONLY;

#include "KnockedCommon.as";
#include "GetSurvivors.as";
#include "Zombie_GlobalMessagesCommon.as";

const u32 unused_time_required = 30*60*2; //time it takes for a sleeper to be available for respawning players to use

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	//set leaving player as sleeper
	
	CBlob@ blob = player.getBlob();
	if (blob is null || blob.hasTag("undead")) return;

	blob.server_SetPlayer(null);

	//immediately slot in a different player if we are leaving as the last alive player
	CPlayer@[] players;
	CBlob@[] survivors = getSurvivors(@players, player);
	if (survivors.length <= 0 && players.length > 0)
	{
		CPlayer@ random_player = players[XORRandom(players.length)];
		blob.server_SetPlayer(random_player);
		
		const string[] inputs = { player.getCharacterName() };
		server_SendGlobalMessage(this, 8, 8, inputs, color_white.color, random_player);

		return;
	}

	blob.set_string("sleeper_name", player.getUsername());
	blob.set_u32("sleeper_time", getGameTime());
	blob.Tag("sleeper");
	blob.Sync("sleeper", true);
	
	if (isKnockable(blob))
		setKnocked(blob, 255, true);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if (newteam == 0)
	{
		onNewPlayerJoin(this, player);
	}
	else
	{
		onPlayerLeave(this, player);
	}
}

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
	//set players to any sleepers that were loaded on the map (saved map)
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		onNewPlayerJoin(this, getPlayer(i));
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	/*string[]@ tokens = player.getUsername().split("~");
	if (tokens.length <= 0) return;
	const string username = tokens[0];*/

	const string username = player.getUsername();

	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;
	
	const u8 sleepersLength = sleepers.length;
	for (u8 i = 0; i < sleepersLength; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (!sleeper.hasTag("dead") && sleeper.get_string("sleeper_name") == username)
		{
			CBlob@ oldBlob = player.getBlob();
			if (oldBlob !is null) oldBlob.server_Die();

			WakeupSleeper(sleeper, player);
			break;
		}
	}
}

void onTick(CRules@ this)
{
	const u32 gametime = getGameTime();
	if (gametime % 250 == 0)
	{
		KnockSleepers();
	}
	
	if (gametime % (30*30) == 0)
	{
		UseSleepersAsRespawn(this);
	}
}

void WakeupSleeper(CBlob@ sleeper, CPlayer@ player)
{
	player.server_setTeamNum(sleeper.getTeamNum());
	
	sleeper.server_SetPlayer(player);
	sleeper.set_string("sleeper_name", "");
	sleeper.Untag("sleeper");
	sleeper.Sync("sleeper", true);
	
	AttachmentPoint@ pickup = sleeper.getAttachments().getAttachmentPoint("PICKUP", false);
	if (pickup !is null && pickup.getOccupied() !is null)
	{
		sleeper.server_DetachFrom(pickup.getOccupied());
	}

	if (sleeper.exists("sleeper_coins"))
	{
		const u16 coins = sleeper.get_u16("sleeper_coins");
		if (coins > player.getCoins())
		{
			player.server_setCoins(coins);
		}
		sleeper.set_u16("sleeper_coins", 0);
	}

	//remove knocked
	if (isKnockable(sleeper))
	{
		sleeper.set_u8(knockedProp, 1);

		CBitStream params;
		params.write_u8(1);
		sleeper.SendCommand(sleeper.getCommandID(knockedProp), params);
	}
}

void KnockSleepers()
{
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;
	
	const u16 sleepersLength = sleepers.length;
	for (u16 i = 0; i < sleepersLength; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (isKnockable(sleeper))
			setKnocked(sleeper, 255, true);
	}
}

void UseSleepersAsRespawn(CRules@ this)
{
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;
	
	const u16 sleepersLength = sleepers.length;
	for (u16 i = 0; i < sleepersLength; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (!sleeper.hasTag("dead") && sleeper.get_u32("sleeper_time") < getGameTime() - unused_time_required)
		{
			const u8 playerCount = getPlayerCount();
			for (u8 p = 0; p < playerCount; p++)
			{
				CPlayer@ player = getPlayer(p);
				if (player is null || player.getBlob() !is null || player.getTeamNum() != 0) continue;
				
				const string[] inputs = { sleeper.get_string("sleeper_name") };
				server_SendGlobalMessage(this, 8, 8, inputs, color_white.color, player);

				WakeupSleeper(sleeper, player);
				break;
			}
		}
	}
}
