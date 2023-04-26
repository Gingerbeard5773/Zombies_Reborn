// Game Music

#define CLIENT_ONLY

enum GameMusicTags
{
	world_ambient,
	world_ambient_underground,
	world_ambient_mountain,
	world_ambient_night,
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,
};

void onInit(CRules@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null) return; //prevents aids on server
	
	AddGameMusic(this, mixer);
}

void onTick(CRules@ this)
{
	if (getGameTime() % 90 != 0) return;

	CMixer@ mixer = getMixer();
	if (mixer is null) return; //prevents aids on server

	//we are only doing ambience ATM, so we can always leave it on
	GameMusicLogic(this, mixer);

	/*if (s_soundon != 0 && s_musicvolume > 0.0f)
	{
		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}*/
}

//sound references with tag
void AddGameMusic(CRules@ this, CMixer@ mixer)
{
	mixer.ResetMixer();
	mixer.AddTrack("Sounds/Music/ambient_forest.ogg", world_ambient);
	mixer.AddTrack("Sounds/Music/ambient_mountain.ogg", world_ambient_mountain);
	mixer.AddTrack("Sounds/Music/ambient_cavern.ogg", world_ambient_underground);
	mixer.AddTrack("Sounds/Music/ambient_night.ogg", world_ambient_night);
	/*mixer.AddTrack("Sounds/Music/KAGWorldIntroShortA.ogg", world_intro);
	mixer.AddTrack("Sounds/Music/KAGWorld1-1a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-2a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-3a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-4a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-5a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-6a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-7a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-8a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-9a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-10a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-11a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-12a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-13+Intro.ogg", world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorld1-14.ogg", world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorldQuickOut.ogg", world_quick_out);*/
}

void GameMusicLogic(CRules@ this, CMixer@ mixer)
{
	CMap@ map = getMap();
	if (map is null) return;

	CBlob@ blob = getLocalPlayerBlob();
	if (blob is null)
	{
		mixer.FadeOutAll(0.0f, 6.0f);
		return;
	}
	Vec2f pos = blob.getPosition();

	const u16 undead_count = this.get_u16("undead count");
	const bool isNight = map.getDayTime() > 0.85f || map.getDayTime() < 0.1f;
	const bool isTwilight = map.getDayTime() > 0.75f && map.getDayTime() < 0.85f;
	const bool cantSeeSky = map.rayCastSolid(pos, Vec2f(pos.x, pos.y - 160.0f));
	const bool isUnderground = map.getLandYAtX(pos.x / map.tilesize) * map.tilesize < pos.y;
	if (isUnderground && cantSeeSky)
	{
		changeMusic(mixer, world_ambient_underground, 2.0f, 4.0f);
	}
	else if (pos.y < 312.0f)
	{
		changeMusic(mixer, world_ambient_mountain, 2.0f, 4.0f);
	}
	else if (undead_count <= 8 && !isTwilight && isNight)
	{
		//if (isNight)
		{
			changeMusic(mixer, world_ambient_night, 2.0f, 4.0f);
		}
		/*else
		{
			changeMusic(mixer, world_ambient, 2.0f, 4.0f);
		}*/
	}
	else
	{
		mixer.FadeOutAll(0.0f, 6.0f);
	}
}

// handle fadeouts / fadeins dynamically
void changeMusic(CMixer@ mixer, int nextTrack, f32 fadeoutTime = 1.6f, f32 fadeinTime = 1.6f)
{
	if (!mixer.isPlaying(nextTrack))
	{
		mixer.FadeOutAll(0.0f, fadeoutTime);
	}

	mixer.FadeInRandom(nextTrack, fadeinTime);
}
