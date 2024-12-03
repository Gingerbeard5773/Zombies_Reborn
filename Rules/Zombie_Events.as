// Zombie Fortress game events

#include "MigrantCommon.as";
#include "ZombieSpawnPos.as";
#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_DaysCommon.as";
#include "GetSurvivors.as";

const u8 GAME_WON = 5;
u16 tim_day;

void onStateChange(CRules@ this, const u8 oldState)
{
	const u8 newState = this.getCurrentState();
	
	switch(newState)
	{
		case GAME_OVER:
		{
			Sound::Play("PortalBreach.ogg");
			break;
		}
		case GAME_WON:
		{
			Sound::Play("FanfareWin.ogg");
			break;
		}
	}
}

void onInit(CRules@ this)
{
	Reset(this);

	addOnNewDayHour(this, @onNewDayHour);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	tim_day = getTimInterval();
}

u16 getTimInterval()
{
	return 15 + XORRandom(11);
}

void onNewDayHour(CRules@ this, u16 day_number, u16 day_hour)
{
	CMap@ map = getMap();

	this.set_bool("pause_undead_spawns", day_number == tim_day);

	switch(day_hour)
	{
		case 3:
		{
			if (day_number > tim_day)
			{
				tim_day = day_number + getTimInterval();
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
			if (day_number == tim_day)
			{
				doTimEvent(this, map);
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
	if (migrants.length > 15) return; //don't if we already have enough migrants

	Vec2f spawn = getZombieSpawnPos(map);
	const u8 amount = 1 + XORRandom(3);
	for (u8 i = 0; i < amount; ++i)
	{
		Vec2f offset(XORRandom(64) - 32, 0);
		CreateMigant(spawn + offset, 0);
	}

	server_SendGlobalMessage(this, amount == 1 ? 5 : 6, 6);
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
				spawns.push_back(blobpos);
			}
		}
	}

	if (spawns.length <= 0) return;

	server_SendGlobalMessage(this, 3, 8);

	Vec2f spawn(spawns[XORRandom(spawns.length)].x + 80 - XORRandom(160), 0);
	server_CreateBlob("traderbomber", 0, spawn);
}

void doSedgwickEvent(CRules@ this, CMap@ map, const u16&in day_number)
{
	if ((day_number+1) % 5 != 0) return; //night before every fifth day
	
	CBlob@[] survivors = getSurvivors();
	if (survivors.length <= 0) return;

	server_SendGlobalMessage(this, 4, 6);
	
	Vec2f spawn = survivors[XORRandom(survivors.length)].getPosition();
	server_CreateBlob("sedgwick", -1, spawn);
}

void doTimEvent(CRules@ this, CMap@ map)
{
	CBlob@[] survivors = getSurvivors();
	if (survivors.length <= 0) return;

	server_SendGlobalMessage(this, 9, 6);

	Vec2f spawn = survivors[XORRandom(survivors.length)].getPosition();
	server_CreateBlob("tim", 0, spawn);
}
