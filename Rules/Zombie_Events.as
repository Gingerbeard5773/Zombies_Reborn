// Zombie Fortress game events

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

void onTick(CRules@ this)
{
	if (!isServer()) return;

	const u32 gameTime = getGameTime();
	
	if (gameTime % 60 == 0)
	{
		checkHourChange(this);
	}

	if (gameTime % 15 == 0)
	{
		//skeletal rain event
		doSkeletalRain(this);
	}
}

void doSkeletalRain(CRules@ this)
{
	u32 skeletal_rain_time = this.get_u32("skeleton_rain");
	if (skeletal_rain_time > 0)
	{
		skeletal_rain_time--;
		this.set_u32("skeleton_rain", skeletal_rain_time);
		
		Vec2f dim = getMap().getMapDimensions();
		server_CreateBlob("skeleton", -1, Vec2f(XORRandom(dim.x), 0));
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
			case 5: //mid day
			{
				doTraderEvent(this);
				break;
			}
		}
	}
}

void doTraderEvent(CRules@ this)
{
	CBlob@[] zombies;
	getBlobsByTag("undead", @zombies);
	if (zombies.length > 10) return; //don't spawn trader if there is too many zombies
	
	//find a proper spawning position near an elegible player
	Vec2f[] spawns;
	const u8 playersLength = getPlayerCount();
	for (u8 i = 0; i < playersLength; ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		CBlob@ playerBlob = player.getBlob();
		if (playerBlob is null) continue;
		
		if (!playerBlob.hasTag("undead"))
			spawns.push_back(playerBlob.getPosition());
	}
	
	if (spawns.length <= 0) return;
	
	//timed global message
	this.SetGlobalMessage("A flying merchant has arrived!");
	this.set_u8("message_timer", 6);
	
	Vec2f spawn(spawns[XORRandom(spawns.length)].x + 200 - XORRandom(400), 0);
	server_CreateBlob("traderbomber", 0, spawn);
}
