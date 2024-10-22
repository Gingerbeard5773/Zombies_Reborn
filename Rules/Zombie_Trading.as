//Zombie Fortress coins mananagement

#define SERVER_ONLY

#include "GameplayEventsCommon.as";
#include "CustomTiles.as";

const int coinsOnRestart = 0;
const int coinsOnDeathLosePercent = 15;

const int coinsOnBuildStoneBlock = 3;
const int coinsOnBuildStoneDoor = 5;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 10;
const int coinsOnBuildStructure = 30;
const int coinsOnBuildComponent = 5;
const int coinsOnBuildIron = 5;
const int coinsOnBuildIronDoor = 10;

const string[] structures =
{
	"windmill",
	"nursery",
	"kitchen",
	"forge",
	"armory",
	"library",
	"apothecary"
};

const string[] components =
{
	"bolter",
	"dispenser",
	"obstructor",
	"spiker"
};

string[] names;

void onInit(CRules@ this)
{
	CGameplayEvent@ func = @awardCoins;
	this.set("awardCoins handle", @func);
}

void onReload(CRules@ this)
{
	CGameplayEvent@ func = @awardCoins;
	this.set("awardCoins handle", @func);
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

		if (tile == CMap::tile_castle)
		{
			coins = coinsOnBuildStoneBlock;
		}
		else if (tile == CMap::tile_wood)
		{
			coins = coinsOnBuildWood;
		}
		else if (tile == CMap::tile_iron)
		{
			coins = coinsOnBuildIron;
		}
		player.setScore(player.getScore() + 1);
	}
	else if (event_id == CGameplayEvent_IDs::BuildBlob)
	{
		string name;
		if (!params.saferead_string(name)) return;

		if (name == "trap_block" ||
			name == "spikes")
		{
			coins = coinsOnBuildStoneBlock;
		}
		else if (name == "stone_door")
		{
			coins = coinsOnBuildStoneDoor;
		}
		else if (name == "wooden_platform" ||
				name == "wooden_door" ||
				name == "bridge" ||
				name == "ladder")
		{
			coins = coinsOnBuildWood;
		}
		else if (name == "building")
		{
			coins = coinsOnBuildWorkshop;
		}
		else if (structures.find(name) > -1)
		{
			coins = coinsOnBuildStructure;
		}
		else if (components.find(name) > -1)
		{
			coins = coinsOnBuildComponent;
		}
		else if (name == "iron_door" || name == "iron_platform")
		{
			coins = coinsOnBuildIronDoor;
		}
	}

	if (coins > 0)
	{
		player.server_setCoins(player.getCoins() + coins);
	}
}
