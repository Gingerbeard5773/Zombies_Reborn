// Zombie Fortress game events

#define SERVER_ONLY

#include "UndeadSpawnPosition.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_DaysCommon.as"
#include "GetSurvivors.as"
#include "BrainTask.as"
#include "SpatialNavigator.as"
#include "PlayerPermissions.as"

void onInit(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);

	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.set_u16("bobert_day", getBobertInterval());
	this.Sync("bobert_day", true);
}

void onReload(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);
}

u16 getBobertInterval()
{
	return 15 + XORRandom(11);
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	CMap@ map = getMap();

	const u16 day_number = this.get_u16("day_number");
	const u16 bobert_day = this.get_u16("bobert_day");

	this.set_bool("pause_undead_spawns", day_number == bobert_day);

	switch(day_hour)
	{
		case 2:
		{
			doEnchanterEvent(this, map, day_number);
			break;
		}
		case 3:
		{
			if (day_number > bobert_day)
			{
				this.set_u16("bobert_day", day_number + getBobertInterval());
				this.Sync("bobert_day", true);
			}
			doMigrantEvent(this, map, day_number);
			break;
		}
		case 5: //mid day
		{
			doTraderEvent(this, map);
			break;
		}
		case 10: //midnight
		{
			if (day_number == bobert_day)
			{
				doBobertEvent(this, map);
				break;
			}
			
			doSedgwickEvent(this, map, day_number);
			break;
		}
	}
}

void doMigrantEvent(CRules@ this, CMap@ map, const u16&in day_number)
{
	if (day_number % 2 != 0) return; //every other day

	if (this.get_u16("undead count") > 15) return; //don't if too many zombies

	CBlob@[] migrants;
	getBlobsByTag("migrant", @migrants);
	if (migrants.length > 10) return; //don't if we already have enough migrants

	Vec2f spawn = getUndeadSpawnPosition();
	const u8 amount = 1 + XORRandom(3);
	const u32 seed = XORRandom(500);
	for (u8 i = 0; i < amount; ++i)
	{
		Vec2f offset(XORRandom(64) - 32, 0);
		const string[] migrant_class = { "builder", "builder", "knight", "archer" };
		CBlob@ blob = server_CreateBlobNoInit(migrant_class[XORRandom(migrant_class.length)]);
		if (blob is null) continue;

		blob.setSexNum(XORRandom(2));
		blob.server_setTeamNum(0);
		blob.setPosition(spawn + offset);
		blob.Init();
		
		TaskManager@ manager = getTaskManager(blob);
		if (manager is null) continue;

		BrainTask@ task = SafetyTask(blob, seed);
		manager.AddTask(task, true);
	}

	server_SendGlobalMessage(this, amount == 1 ? "Migrant1" : "Migrant2", 6);
}

void doTraderEvent(CRules@ this, CMap@ map)
{
	//find a proper spawning position near an elegible player
	const bool doGroundCheck = this.get_u16("undead count") > 20;
	Vec2f[] spawns;
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		CBlob@ playerBlob = player.getBlob();
		if (playerBlob is null || playerBlob.hasTag("undead")) continue;
		
		Vec2f blobpos = playerBlob.getPosition();
		Vec2f groundpos;
		//raycast from sky to ground
		if (map.rayCastSolid(Vec2f(blobpos.x, 0), Vec2f(blobpos.x, map.tilemapheight * map.tilesize), groundpos))
		{
			CBlob@[] blobs;
			map.getBlobsInRadius(groundpos, 240.0f, @blobs);

			bool isGroundClearOfUndead = true;
			if (doGroundCheck)
			{
				for (u16 i = 0; i < blobs.length; i++)
				{
					CBlob@ blob = blobs[i];
					if (!blob.hasTag("undead")) continue;
					
					isGroundClearOfUndead = false;
					break;
				}
			}
			
			if (isGroundClearOfUndead)
			{
				const f32 spawnheight = 500.0f;
				Vec2f spawnpos = blobpos;
				spawnpos.y = groundpos.y > spawnheight ? 0 : groundpos.y - spawnheight;
				spawnpos.x += 80 - XORRandom(160);
				spawns.push_back(spawnpos);
			}
		}
	}

	if (spawns.length <= 0) return;

	server_SendGlobalMessage(this, "Trader", 8);

	Vec2f spawn = spawns[XORRandom(spawns.length)];

	server_CreateBlob("traderbomber", 0, spawn);
}

void doSedgwickEvent(CRules@ this, CMap@ map, const u16&in day_number)
{
	if ((day_number+1) % 5 != 0) return; //night before every fifth day
	
	CBlob@[] survivors = getSurvivors();
	if (survivors.length <= 0) return;

	server_SendGlobalMessage(this, "Sedgwick", 6);
	
	Vec2f spawn = survivors[XORRandom(survivors.length)].getPosition();

	server_CreateBlob("sedgwick", -1, spawn);
}

void doBobertEvent(CRules@ this, CMap@ map)
{
	CBlob@[] spawners = getSurvivors();
	if (spawners.length == 0) return;

	Vec2f origin = spawners[XORRandom(spawners.length)].getPosition();
	Navigator navigator(origin);
	navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getTouchingBlobsCost, @getWaterCost };
	navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isUnobstructedByBlobs, @isOnGround };
	Vec2f spawn = navigator.getBestPositionFromOrigin(20, 20);

	server_SendGlobalMessage(this, "Bobert", 6);

	server_CreateBlob("bobert", 0, spawn);
}

void doEnchanterEvent(CRules@ this, CMap@ map, const u16&in day_number)
{
	if (day_number % 10 != 0) return; //every ten days

	CBlob@[] spawners = getSurvivors();
	getBlobsByTag("building", @spawners);
	if (spawners.length == 0) return;
	
	Vec2f origin = spawners[XORRandom(spawners.length)].getPosition();
	Navigator navigator(origin);
	navigator.space_above = 4;
	navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getTouchingBlobsCost, @getWaterCost };
	navigator.valid_evaluators = { @isInMap, @isOpenSpace, @hasOpenSpaceAbove, @isUnobstructedByBlobs, @isOnGround };
	Vec2f spawn = navigator.getBestPositionFromOrigin(32, 32);

	server_SendGlobalMessage(this, "Enchanter", 6);

	server_CreateBlob("enchanter", 0, spawn);
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	bool isAdmin, isSuperAdmin;
	getPermissions(player, isAdmin, isSuperAdmin);
	if (!isSuperAdmin) return true;

	if (text_in == "!trader")
	{
		doTraderEvent(this, getMap());
	}
	else if (text_in == "!bobert")
	{
		doBobertEvent(this, getMap());
	}
	else if (text_in == "!enchanter")
	{
		doEnchanterEvent(this, getMap(), 10);
	}

	return true;
}
