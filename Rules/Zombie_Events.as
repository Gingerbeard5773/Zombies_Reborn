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
	
	this.set_u16("pyromancer_day", getPyromancerInterval());
	this.Sync("pyromancer_day", true);
}

void onReload(CRules@ this)
{
	addOnNewDayHour(this, @onNewDayHour);
}

u16 getBobertInterval()
{
	return 15 + XORRandom(11);
}

u16 getPyromancerInterval()
{
	return 20 + XORRandom(11);
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	const u16 day_number = this.get_u16("day_number");
	const u16 bobert_day = this.get_u16("bobert_day");
	const u16 pyromancer_day = this.get_u16("pyromancer_day");

	const bool pause = day_number == bobert_day || day_number == pyromancer_day;
	this.set_bool("pause_undead_spawns", pause);

	switch(day_hour)
	{
		case 2: //new day
		{
			if (day_number > bobert_day)
			{
				this.set_u16("bobert_day", day_number + getBobertInterval());
				this.Sync("bobert_day", true);
			}

			if (day_number > pyromancer_day)
			{
				this.set_u16("pyromancer_day", day_number + getPyromancerInterval());
				this.Sync("pyromancer_day", true);
			}

			doEnchanterEvent(this, day_number);
			break;
		}
		case 3:
		{
			if (day_number == pyromancer_day)
			{
				doPyromancerEvent(this);
				break;
			}

			doMigrantEvent(this, day_number);
			break;
		}
		case 5: //mid day
		{
			doTraderEvent(this);
			break;
		}
		case 9:
		{
			if (this.get_bool("pause_undead_spawns"))
			{
				server_SendGlobalMessage(this, "PeacefulNight", 6);
			}
		}
		case 10: //midnight
		{
			if (day_number == bobert_day)
			{
				doBobertEvent(this);
				break;
			}
			
			doSedgwickEvent(this, day_number);
			break;
		}
	}
}

void doMigrantEvent(CRules@ this, const u16&in day_number)
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

void doTraderEvent(CRules@ this)
{
	//find a proper spawning position near an elegible player
	CMap@ map = getMap();
	const bool check_for_undeads = this.get_u16("undead count") > 20;
	Vec2f[] spawns;
	CBlob@[] survivors = getSurvivors();
	for (int i = 0; i < survivors.length; ++i)
	{
		Vec2f pos = survivors[i].getPosition();
		Vec2f ground_pos = Vec2f(pos.x, map.tilemapheight * map.tilesize);
		//raycast from sky to ground
		if (map.rayCastSolid(Vec2f(pos.x, 0), ground_pos, ground_pos))
		{
			CBlob@[] blobs;
			map.getBlobsInRadius(ground_pos, 240.0f, @blobs);

			bool is_safe_spawn = true;
			if (check_for_undeads)
			{
				for (int u = 0; u < blobs.length; u++)
				{
					CBlob@ blob = blobs[u];
					if (!blob.hasTag("undead")) continue;
					
					is_safe_spawn = false;
					break;
				}
			}
			
			if (is_safe_spawn)
			{
				const f32 spawnheight = 500.0f;
				Vec2f spawn = pos;
				spawn.y = ground_pos.y > spawnheight ? 0 : ground_pos.y - spawnheight;
				spawn.x += 80 - XORRandom(160);
				spawns.push_back(spawn);
			}
		}
	}

	if (spawns.length <= 0) return;

	Vec2f spawn = spawns[XORRandom(spawns.length)];

	server_SendGlobalMessage(this, "Trader", 8);

	server_CreateBlob("traderbomber", 0, spawn);
}

void doSedgwickEvent(CRules@ this, const u16&in day_number)
{
	if ((day_number+1) % 5 != 0) return; //night before every fifth day
	
	CBlob@[] survivors = getSurvivors();
	if (survivors.length <= 0) return;

	Vec2f spawn = survivors[XORRandom(survivors.length)].getPosition();

	server_SendGlobalMessage(this, "Sedgwick", 6);

	server_CreateBlob("sedgwick", -1, spawn);
}

void doBobertEvent(CRules@ this)
{
	CBlob@[] spawners = getSurvivors();
	if (spawners.length == 0) return;

	Vec2f origin = spawners[XORRandom(spawners.length)].getPosition();
	Navigator navigator(origin);
	navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getTouchingBlobsCost, @getWaterCost };
	navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isUnobstructedByBlobs, @isOnGround };
	Vec2f spawn = navigator.getBestPositionFromOrigin(160.0f);

	server_SendGlobalMessage(this, "Bobert", 6);

	server_CreateBlob("bobert", 0, spawn);
}

void doEnchanterEvent(CRules@ this, const u16&in day_number)
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
	Vec2f spawn = navigator.getBestPositionFromOrigin(256.0f);

	server_SendGlobalMessage(this, "Enchanter", 6);

	server_CreateBlob("enchanter", 0, spawn);
}

void doPyromancerEvent(CRules@ this)
{
	CBlob@[] spawners = getSurvivors();
	if (spawners.length == 0) return;
	
	Vec2f origin = spawners[XORRandom(spawners.length)].getPosition();
	Navigator navigator(origin);
	navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getWaterCost };
	navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isUnobstructedByBlobs };
	Vec2f spawn = navigator.getBestPositionFromOrigin(160.0f);

	server_SendGlobalMessage(this, "Pyromancer", 6);

	server_CreateBlob("pyromancer", -1, spawn);
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	bool isAdmin, isSuperAdmin;
	getPermissions(player, isAdmin, isSuperAdmin);
	if (!isSuperAdmin) return true;

	if (text_in == "!trader")
	{
		doTraderEvent(this);
	}
	else if (text_in == "!sedgwick")
	{
		doSedgwickEvent(this, 4);
	}
	else if (text_in == "!bobert")
	{
		doBobertEvent(this);
	}
	else if (text_in == "!enchanter")
	{
		doEnchanterEvent(this, 10);
	}
	else if (text_in == "!pyromancer")
	{
		doPyromancerEvent(this);
	}
	else if (text_in == "!events")
	{
		server_SendGlobalMessage(this, "Bobert Day: "+this.get_u16("bobert_day"), 6);
		server_SendGlobalMessage(this, "Pyromancer Day: "+this.get_u16("pyromancer_day"), 6);
	}

	return true;
}
