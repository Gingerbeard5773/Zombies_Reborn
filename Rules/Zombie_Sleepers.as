//Allow reconnecting players to get back into the game fast

#define SERVER_ONLY

#include "KnockedCommon.as"
#include "GetSurvivors.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_DaysCommon.as"

const u32 unused_time_required = 30*60*2; //time it takes for a sleeper to be available for respawning players to use
const u8 maximum_migrant_respawns_per_day = 1; //amount of migrant respawns available per day before its shut off

u8 migrant_respawns_used = 0;

void onInit(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);

	Reset(this);
}

void onReload(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	//set players to any sleepers that were loaded on the map (saved map)
	for (int i = 0; i < getPlayerCount(); i++)
	{
		onNewPlayerJoin(this, getPlayer(i));
	}

	migrant_respawns_used = 0;
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	if (day_hour != this.daycycle_start*10) return;

	//reset our available migrant respawns every new day
	migrant_respawns_used = 0;
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	//set dead player to a migrant or sleeper if our player is solo

	CPlayer@[] players;
	CBlob@[] survivors = getSurvivors(@players);
	if (survivors.length > 0 || players.length != 1) return;

	if (victim !is players[0]) return;

	if (migrant_respawns_used == maximum_migrant_respawns_per_day) return;

	CBlob@[] migrants;
	getBlobsByTag("migrant", @migrants);
	getBlobsByTag("sleeper", @migrants);

	for (int i = 0; i < migrants.length; i++)
	{
		CBlob@ migrant = migrants[i];
		if (migrant.hasTag("dead")) continue;

		WakeupSleeper(migrant, victim);

		const string migrant_name = migrant.hasTag("sleeper") ? migrant.get_string("sleeper_name") : migrant.getInventoryName();
		const string[] inputs = { migrant_name };
		server_SendGlobalMessage(this, "Respawn2", 8, inputs, color_white.color, victim);

		if (++migrant_respawns_used == maximum_migrant_respawns_per_day)
		{
			server_SendGlobalMessage(this, "Respawn4", 8, color_white.color, victim);
		}

		break;
	}
}

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
		server_SendGlobalMessage(this, "Respawn2", 8, inputs, color_white.color, random_player);

		return;
	}

	blob.set_string("sleeper_name", player.getUsername());
	blob.set_u32("sleeper_time", getGameTime());
	blob.Tag("sleeper");
	blob.Sync("sleeper", true);
	blob.Sync("sleeper_name", true);

	if (isKnockable(blob))
	{
		setKnocked(blob, 255, true);
	}
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

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (player is null) return;

	/*string[]@ tokens = player.getUsername().split("~");
	if (tokens.length <= 0) return;
	const string username = tokens[0];*/

	const string username = player.getUsername();

	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;

	for (int i = 0; i < sleepers.length; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (!sleeper.hasTag("dead") && sleeper.get_string("sleeper_name") == username)
		{
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
	sleeper.Sync("sleeper_name", true);
	
	const string[] detach_points = { "PICKUP", "WORKER" };
	for (int i = 0; i < detach_points.length; i++)
	{
		if (sleeper.isAttachedToPoint(detach_points[i]))
		{
			sleeper.server_DetachFromAll();
			break;
		}
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

	//hack fix for emote hotkey error
	if (isClient())
	{
		getRules().Tag("reload emotes");
	}
}

void KnockSleepers()
{
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;

	for (int i = 0; i < sleepers.length; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (isKnockable(sleeper))
		{
			setKnocked(sleeper, 255, true);
		}
	}
}

void UseSleepersAsRespawn(CRules@ this)
{
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;

	for (int i = 0; i < sleepers.length; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (!sleeper.hasTag("dead") && sleeper.get_u32("sleeper_time") < getGameTime() - unused_time_required)
		{
			for (int p = 0; p < getPlayerCount(); p++)
			{
				CPlayer@ player = getPlayer(p);
				if (player is null || player.getBlob() !is null || player.getTeamNum() != 0) continue;

				const string[] inputs = { sleeper.get_string("sleeper_name") };
				server_SendGlobalMessage(this, "Respawn2", 8, inputs, color_white.color, player);

				WakeupSleeper(sleeper, player);
				break;
			}
		}
	}
}
