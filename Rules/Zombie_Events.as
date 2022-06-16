// Zombie Fortress game events

const u8 GAME_WON = 5;

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
	//skeletal rain event
	if (isServer() && getGameTime() % 15 == 0)
	{
		u32 skeletal_rain_time = this.get_u32("skeleton_rain");
		if (skeletal_rain_time > 0)
		{
			skeletal_rain_time--;
			this.set_u32("skeleton_rain", skeletal_rain_time);
			
			server_CreateBlob("skeleton", -1, getSkeletonSpawn());
		}
	}
}

Vec2f getSkeletonSpawn()
{
	Vec2f dim = getMap().getMapDimensions();
	return Vec2f(XORRandom(dim.x), 0);
}
