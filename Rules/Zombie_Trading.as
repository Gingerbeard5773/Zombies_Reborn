//Zombie Fortress coins mananagement

#define SERVER_ONLY

#include "GameplayEventsCommon.as"
#include "CustomTiles.as"
#include "Zombie_StatisticsCommon.as"

const int coinsOnRestart = 0;
const int coinsOnDeathLosePercent = 15;

string[] names;
dictionary awards;

class CoinsAward
{
	string name;
	u16 coins;
	string statistic;

	CoinsAward(const string&in name, const u16&in coins, const string&in statistic = "")
	{
		this.name = name;
		this.coins = coins;
		this.statistic = statistic;
	}
}

void AddAward(const u16&in tile, const u16&in coins, const string&in statistic = "")
{
	AddAward("tile_" + tile, coins, statistic);
}

void AddAward(const string&in name, const u16&in coins, const string&in statistic = "")
{
	CoinsAward award(name, coins, statistic);
	awards.set(name, @award);
}

void onInit(CRules@ this)
{
	CGameplayEvent@ func = @awardCoins;
	this.set("awardCoins handle", @func);

	AddAward(CMap::tile_wood,    1,   "wood_blocks_placed");
	AddAward(CMap::tile_castle,  3,   "stone_blocks_placed");
	AddAward(CMap::tile_iron,    5,   "iron_blocks_placed");
	AddAward(CMap::tile_ground,  5,   "dirt_blocks_placed");

	AddAward("stone_door",       5,   "doors_placed");
	AddAward("trap_block",       3,   "trap_blocks_placed");
	AddAward("spikes",           3,   "spikes_placed");

	AddAward("wooden_door",      1,   "doors_placed");
	AddAward("wooden_platform",  1,   "platforms_placed");
	AddAward("bridge",           1,   "platforms_placed");
	AddAward("ladder",           1,   "ladders_placed");

	AddAward("iron_door",        10,  "doors_placed");
	AddAward("iron_platform",    10,  "platforms_placed");
	AddAward("iron_spikes",      10,  "spikes_placed");

	AddAward("building",         10,  "buildings_placed");
	AddAward("windmill",         30,  "buildings_placed");
	AddAward("kitchen",          30,  "buildings_placed");
	AddAward("forge",            30,  "buildings_placed");
	AddAward("armory",           30,  "buildings_placed");
	AddAward("library",          50,  "buildings_placed");
	AddAward("apothecary",       30,  "buildings_placed");

	AddAward("bolter",           5,   "components_placed");
	AddAward("dispenser",        5,   "components_placed");
	AddAward("obstructor",       5,   "components_placed");
	AddAward("spiker",           5,   "components_placed");
	AddAward("magazine",         5,   "components_placed");
	AddAward("pressure_plate",   5,   "components_placed");

	AddAward("wire",             2,   "components_placed");
	AddAward("elbow",            2,   "components_placed");
	AddAward("tee",              2,   "components_placed");
	AddAward("junction",         2,   "components_placed");
	AddAward("diode",            2,   "components_placed");
	AddAward("resistor",         2,   "components_placed");
	AddAward("inverter",         2,   "components_placed");
	AddAward("oscillator",       2,   "components_placed");
	AddAward("transistor",       2,   "components_placed");
	AddAward("toggle",           2,   "components_placed");
	AddAward("randomizer",       2,   "components_placed");
	AddAward("lever",            2,   "components_placed");
	AddAward("button",           2,   "components_placed");
	AddAward("coin_slot",        2,   "components_placed");
	AddAward("sensor",           2,   "components_placed");
	AddAward("lamp",             2,   "components_placed");
	AddAward("emitter",          2,   "components_placed");
	AddAward("receiver",         2,   "components_placed");
}

void onReload(CRules@ this)
{
	CGameplayEvent@ func = @awardCoins;
	this.set("awardCoins handle", @func);

	onInit(this);
}

void onRestart(CRules@ this)
{
	names.clear();
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		player.server_setCoins(coinsOnRestart);
		names.push_back(player.getUsername());
	}
}

//set coins to player when they first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player is null) return;

	const string username = player.getUsername();
	if (names.find(username) > -1) return;

	names.push_back(username);
	player.server_setCoins(coinsOnRestart);
}

//lose coins when dying
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim is null) return;

	const int lost = victim.getCoins() * (coinsOnDeathLosePercent * 0.01f);

	victim.server_setCoins(victim.getCoins() - lost);

	//drop coins
	CBlob@ blob = victim.getBlob();
	if (blob !is null)
		server_DropCoins(blob.getPosition(), lost*0.75f + XORRandom(lost*0.25f));
}

// Gameplay events stuff

void awardCoins(CBitStream@ params)
{
	params.ResetBitIndex();

	u8 event_id;
	if (!params.saferead_u8(event_id)) return;

	u16 player_id;
	if (!params.saferead_u16(player_id)) return;

	CPlayer@ player = getPlayerByNetworkId(player_id);
	if (player is null) return;

	u16 coins = 0;

	if (event_id == CGameplayEvent_IDs::BuildBlock)
	{
		u16 tile;
		if (!params.saferead_u16(tile)) return;

		coins = getCoinsFromAward("tile_" + tile, player);

		Statistics::server_Add("blocks_placed", 1, player);
	}
	else if (event_id == CGameplayEvent_IDs::BuildBlob)
	{
		string name;
		if (!params.saferead_string(name)) return;

		coins = getCoinsFromAward(name, player);
	}

	if (coins > 0)
	{
		player.server_setCoins(player.getCoins() + coins);
	}
}

u16 getCoinsFromAward(const string&in name, CPlayer@ player)
{
	CoinsAward@ award;
	if (!awards.get(name, @award)) return 0;

	if (!award.statistic.isEmpty())
	{
		Statistics::server_Add(award.statistic, 1, player);
	}

	return award.coins;
}
