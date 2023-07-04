// Zombie Fortress game events

#include "MigrantCommon.as";
#include "ZombieSpawnPos.as";

const u8 GAME_WON = 5;
f32 lastDayHour;

void onStateChange(CRules@ this, const u8 oldState)
{
	const u8 newState = this.getCurrentState();
	
	switch(newState)
	{
		case GAME_OVER:
		{
			Sound::Play("FanfareLose.ogg");
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
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	//setup skelepede night event
	const u8[] skelepede_possible_days = {6, 7, 8, 11, 12}; 
	this.set_u8("skelepede day", skelepede_possible_days[XORRandom(skelepede_possible_days.length)]);
}

void onTick(CRules@ this)
{
	if (!isServer()) return;
	
	if (getGameTime() % 60 == 0)
	{
		checkHourChange(this);
	}
}

void checkHourChange(CRules@ this)
{
	CMap@ map = getMap();
	const u8 dayHour = Maths::Roundf(map.getDayTime()*10);
	if (dayHour != lastDayHour)
	{
		lastDayHour = dayHour;
		switch(dayHour)
		{
			case 3:
			{
				doMigrantEvent(this, map);
				break;
			}
			case 5: //mid day
			{
				doTraderEvent(this, map);
				break;
			}
			case 10: //midnight
			{
				doSedgwickEvent(this, map);
				doSkelepedeEvent(this, map);
				break;
			}
		}
	}
}

void doMigrantEvent(CRules@ this, CMap@ map)
{
	//if (this.get_u8("day_number") % 2 != 0) return; //every other day

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

	this.SetGlobalMessage(amount == 1 ? "A refugee has arrived!": "Refugees have arrived!");
	this.set_u8("message_timer", 6);
}

void doTraderEvent(CRules@ this, CMap@ map)
{
	if (this.get_u16("undead count") > 10) return; //don't spawn trader if there is too many zombies
	
	//find a proper spawning position near an elegible player
	Vec2f[] spawns;
	const u8 playersLength = getPlayerCount();
	for (u8 i = 0; i < playersLength; ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		CBlob@ playerBlob = player.getBlob();
		if (playerBlob is null || playerBlob.hasTag("undead")) continue;
		
		spawns.push_back(playerBlob.getPosition());
	}
	
	if (spawns.length <= 0) return;
	
	this.SetGlobalMessage("A flying merchant has arrived!");
	this.set_u8("message_timer", 6);
	
	Vec2f spawn(spawns[XORRandom(spawns.length)].x + 200 - XORRandom(400), 0);
	
	if (map.isTileSolid(map.getTile(spawn)))
	{
		//in case of roof
		Vec2f[] markers;
		if (map.getMarkers("zombie_spawn", markers))
			spawn = markers[XORRandom(markers.length)];
	}
	
	server_CreateBlob("traderbomber", 0, spawn);
}

void doSedgwickEvent(CRules@ this, CMap@ map)
{
	if ((this.get_u8("day_number")+1) % 5 != 0) return; //night before every fifth day
	
	Vec2f[] spawns;
	if (!map.getMarkers("zombie_spawn", spawns)) //no markers? spawn on someone
	{
		const u8 playersLength = getPlayerCount();
		for (u8 i = 0; i < playersLength; ++i)
		{
			CPlayer@ player = getPlayer(i);
			if (player is null) continue;
			
			CBlob@ playerBlob = player.getBlob();
			if (playerBlob is null) continue;
			
			spawns.push_back(playerBlob.getPosition());
		}
		
		if (spawns.length <= 0) return;
	}
	
	this.SetGlobalMessage("Sedgwick the necromancer has appeared!");
	this.set_u8("message_timer", 6);
	
	server_CreateBlob("sedgwick", -1, spawns[XORRandom(spawns.length)]);
}

void doSkelepedeEvent(CRules@ this, CMap@ map)
{
	if (this.get_u8("day_number") != this.get_u8("skelepede day")) return;

	Vec2f dim = map.getMapDimensions();
	u8 survivorsCount = 0;
	const u8 playersLength = getPlayerCount();
	for (u8 i = 0; i < playersLength; ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		CBlob@ playerBlob = player.getBlob();
		if (playerBlob is null || playerBlob.hasTag("undead")) continue;

		survivorsCount++;
	}
	survivorsCount /= 4;
	for (u8 i = 0; i < 3 + survivorsCount; ++i)
	{
		Vec2f spawn(XORRandom(dim.x), dim.y + 50 + XORRandom(600));
		server_CreateBlob("skelepede", -1, spawn);
	}
	
	//setup next skelepede night event (while making sure we dont overlap on sedgwick)
	u8 next_skelepede_day;
	do 
		next_skelepede_day = this.get_u8("day_number") + 5 + XORRandom(5);
	while((next_skelepede_day+1) % 5 == 0);
	
	this.set_u8("skelepede day", next_skelepede_day);
}
