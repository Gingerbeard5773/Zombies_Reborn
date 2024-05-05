// antagonist asshole

#include "ParticleTeleport.as";

enum SpellNum
{
	spell_skeleton = 0,
	spell_wraith,
	spell_delivery,
	spell_portal,
	spell_end
};

const u8[] spell_countdown =
{
	20,      //spell_skeleton
	10,      //spell_wraith
	10,      //spell_delivery
	12,      //spell_portal
	5        //spell_end
};

void onInit(CBlob@ this)
{
	this.server_setTeamNum(-1);
	this.set_f32("gib health", 0.0f);
	
	CSprite@ sprite = this.getSprite();
	sprite.ReloadSprites(3, 0); //purple
	
	Sound::Play("EvilNotice.ogg");
	ParticleZombieLightning(this.getPosition());
	
	this.SetLight(false);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 150, 240, 171));

	server_SetSpell(this, XORRandom(spell_end));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() < 5*30) return;
	
	this.setKeyPressed(key_action1, this.getShape().isStatic() && this.getTimeToDie() < 0); //for anim
	
	if (getGameTime() % 30 == 0)
	{
		if (!this.getShape().isStatic()) //teleport to new area
		{
			ParticleTeleport(this.getPosition());
			
			if (isServer())
			{
				CMap@ map = getMap();
				Vec2f dim = map.getMapDimensions();
				
				const int x = dim.x/4 + XORRandom((dim.x/4)*2);
				const int ceiling = getMapCeiling(map, x);
				
				Vec2f end;
				map.rayCastSolidNoBlobs(Vec2f(x, ceiling), Vec2f(x, dim.y), end);
				this.set_Vec2f("teleport pos", Vec2f(x, ceiling + (end.y - ceiling) / 2));
				this.Sync("teleport pos", true);
			}
			this.setPosition(this.get_Vec2f("teleport pos"));
			
			this.SetLight(true);
			this.getShape().SetStatic(true);
		}
		
		const u8 spell = this.get_u8("spell num");
		const u8 countdown = this.get_u8("spell countdown");
		switch(spell)
		{
			case spell_skeleton:  SpellSkeletonRain(this, countdown);  break;
			case spell_wraith:    SpellWraith(this, countdown);        break;
			case spell_delivery:  SpellDelivery(this, countdown);      break;
			case spell_portal:    SpellPortal(this, countdown);        break;
			case spell_end:       SedgwickDeparture(this, countdown);  break;
		}

		if (isServer())
		{
			this.set_u8("spell countdown", Maths::Max(this.get_u8("spell countdown") - 1, 0));
			this.Sync("spell countdown", true);
		}
	}
}

// summon skeletons from the sky
void SpellSkeletonRain(CBlob@ this, const u8&in countdown)
{	
	if (countdown < 12)
	{
		const u16 skeleton_count = 3 + Maths::Floor(getPlayerCount()/3);
		if (isServer())
		{
			CMap@ map = getMap();
			for (u16 i = 0; i < skeleton_count; ++i)
			{
				//spawn at ceiling
				const int x = XORRandom(map.tilemapwidth*8);
				server_CreateBlob("skeleton", -1, Vec2f(x, getMapCeiling(map, x) + 8));
			}
		}
		if (isClient())
		{
			for (u16 i = 0; i < skeleton_count; i++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 2, 50.0f);
				ParticleAnimated("spirit.png", this.getPosition(), vel, 0, 1.3f, 8, 0.0f, true);
			}

			this.getSprite().PlaySound("WraithSpawn.ogg", 2.5f, 1.2f);
			
			if (countdown % 2 == 0)
				RemoveOrb(this, countdown/2, false);
		}
		
		if (countdown == 0)
		{
			server_SetSpell(this, spell_end);
		}
	}
	else if (countdown > 12)
	{
		AddOrb(this.getSprite(), 0, countdown - 14, 1.0f);
	}
}

// convert skeletons into wraiths
void SpellWraith(CBlob@ this, const u8&in countdown)
{
	CBlob@[] blobs;
	if (!getBlobsByName("skeleton", @blobs))
	{
		server_SetSpell(this, XORRandom(spell_end));
		return;
	}
	
	if (countdown == 0) //activate spell
	{
		const u16 blobsLength = blobs.length;
		for (u16 i = 0; i < blobsLength; ++i)
		{
			CBlob@ skeleton = blobs[i];
			
			if (isClient())
			{
				ParticleAnimated("SmallExplosion" + (XORRandom(3) + 1) + ".png",
					 skeleton.getPosition(), Vec2f(0, 0.5f), 0.0f, 1.0f, 3 + XORRandom(3), -0.1f, true);
				
				CSprite@ blobSprite = skeleton.getSprite();
				blobSprite.PlaySound("KegExplosion.ogg", 0.5f);
				blobSprite.Gib();
				ShakeScreen(200, 50, skeleton.getPosition());
			}
			if (isServer())
			{
				server_CreateBlob("wraith", -1, skeleton.getPosition());
				skeleton.server_Die();
			}
		}
		
		if (isClient())
		{
			Sound::Play("SuddenGib.ogg");
			
			for (u8 i = 0; i < 6; ++i)
			{
				RemoveOrb(this, i);
			}
		}
		
		server_SetSpell(this, spell_end);
	}
	else
	{
		AddOrb(this.getSprite(), 1, countdown - 1, 0.7f);
	}
}

// teleport zombies over players
void SpellDelivery(CBlob@ this, const u8&in countdown)
{
	CBlob@[] blobs;
	if (!getBlobsByTag("undead", @blobs))
	{
		server_SetSpell(this, XORRandom(spell_end));
		return;
	}
	
	if (countdown == 0) //activate spell
	{
		//find applicable players
		CBlob@[] survivors;
		const u8 playersLength = getPlayerCount();
		for (u8 i = 0; i < playersLength; ++i)
		{
			CPlayer@ player = getPlayer(i);
			if (player is null) continue;
			
			CBlob@ playerBlob = player.getBlob();
			if (playerBlob !is null && !playerBlob.hasTag("undead"))
			{
				survivors.push_back(playerBlob);
			}
		}
		
		const u8 survivorsLength = survivors.length;
		if (survivorsLength <= 0)
		{
			server_SetSpell(this, XORRandom(spell_end));
			return;
		}
		
		const u16 undeadPerPlayer = blobs.length/survivorsLength;
		u16 undeadIndex = 0;
		for (u8 i = 0; i < survivorsLength; ++i)
		{
			CBlob@ survivor = survivors[i];
			
			Vec2f pos = survivor.getPosition();
			CMap@ map = getMap();
			const int ceiling = getMapCeiling(map, pos.x);
			Vec2f end;
			map.rayCastSolidNoBlobs(Vec2f(pos.x, ceiling), pos, end);
			
			const Vec2f deliveryPos = Vec2f(pos.x, ceiling + (end.y - ceiling) / 2);
			
			//share zombies to players equally
			for (u16 q = 0; q < undeadPerPlayer; ++q)
			{
				CBlob@ undead = blobs[undeadIndex];
				if (isClient())
				{
					ParticleZombieLightning(undead.getPosition());
					ParticleZombieLightning(deliveryPos);
					ShakeScreen(170, 50, deliveryPos);
				}
				if (isServer())
				{
					undead.setPosition(deliveryPos);
					undead.set_Vec2f("brain_destination", pos); //tell the zombie where to look
				}
				
				undeadIndex++;
			}
		}
		
		if (isClient())
		{
			Sound::Play2D("OrbExplosion.ogg", 3.0f, 0.0f);
			
			for (u8 i = 0; i < 6; ++i)
			{
				RemoveOrb(this, i);
			}
		}
		
		server_SetSpell(this, spell_end);
	}
	else
	{
		AddOrb(this.getSprite(), 5, countdown - 1, 2.0f);
	}
}

// summon a zombie portal if a player is underground
void SpellPortal(CBlob@ this, const u8&in countdown)
{
	Vec2f spawn = this.get_Vec2f("spell portal spawn");
	
	if (countdown == 0) //activate spell
	{
		if (isServer())
		{
			server_CreateBlob("zombieportal", -1, spawn);
		}
		if (isClient())
		{
			Sound::Play("BuildingExplosion.ogg", spawn, 2.0f, 0.9f);
			Sound::Play("Bomb.ogg", spawn, 2.0f, 0.9f);
			
			Vec2f offset(16, 16);
			for (u8 i = 0; i < 8; ++i)
			{
				CParticle@ p = ParticleAnimated("FireFlash.png", spawn+offset, offset/16, -offset.Angle(), 1.0f, 2, 0.0f, true);
				p.Z = 1000.0f;
				offset.RotateBy(45);
			}
			
			for (u8 i = 0; i < 6; ++i)
			{
				RemoveOrb(this, i);
			}
		}
		
		server_SetSpell(this, spell_end);
	}
	else
	{
		AddOrb(this.getSprite(), 3, countdown - 1, 0.8f);
	}
	
	if (isClient() && countdown < 7) //fire circles
	{
		Vec2f offset(16, 16);
		for (u8 i = 0; i < 8; ++i)
		{
			CParticle@ p = ParticleAnimated("FireFlash.png", spawn+offset, -offset/16, -offset.Angle(), 1.0f, 2, 0.0f, true);
			p.Z = 1000.0f;
			offset.RotateBy(45);
		}
	}
}

void server_SetPortalSpawn(CBlob@ this)
{
	if (!isServer()) return;
	
	CMap@ map = getMap();
	Vec2f spawn = Vec2f_zero;
	int most_ground = 0;
	const u8 playersLength = getPlayerCount();
	for (u8 i = 0; i < playersLength; ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		CBlob@ playerBlob = player.getBlob();
		if (playerBlob is null || playerBlob.hasTag("undead")) continue;
		
		Vec2f pos = playerBlob.getPosition();
		if ((map.getLandYAtX(pos.x / map.tilesize) * map.tilesize) > pos.y) continue;
		
		int ground_tiles = 0;
		for (int i = pos.y/8; i > 0; i--)
		{
			TileType type = map.getTile(Vec2f(pos.x, i*8)).type;
			if (!map.isTileGroundStuff(type) || type == CMap::tile_ground_back) continue;
			ground_tiles++;
		}
		
		if (ground_tiles > most_ground && ground_tiles > 1)
		{
			Vec2f end;
			map.rayCastSolidNoBlobs(pos, Vec2f(pos.x, map.tilemapheight*8 - 8), end);
			spawn = end + Vec2f(0, -24);
			most_ground = ground_tiles;
		}
	}
	
	if (spawn == Vec2f_zero)
	{
		server_SetSpell(this, XORRandom(spell_end));
		return;
	}
	
	this.set_Vec2f("spell portal spawn", spawn);
	this.Sync("spell portal spawn", true);
}

void server_SetSpell(CBlob@ this, const u8&in spell_num)
{
	if (!isServer()) return;
	
	this.set_u8("spell num", spell_num);
	this.Sync("spell num", true);
	this.set_u8("spell countdown", spell_countdown[spell_num]);
	this.Sync("spell countdown", true);
	
	if (spell_num == spell_portal)
	{
		server_SetPortalSpawn(this);
	}
}

void SedgwickDeparture(CBlob@ this, const u8&in countdown)
{
	this.setKeyPressed(key_action1, false);
	this.SetLight(false);
	if (this.getTimeToDie() < 0 && isServer())
	{
		this.server_SetTimeToDie(spell_countdown[spell_end]);
	}
}

void AddOrb(CSprite@ sprite, const u8&in team, const u8&in orbnum, const f32&in pitch)
{
	if (isClient())
	{
		if (orbnum > 6) return;
		
		CSpriteLayer@ orb = sprite.getSpriteLayer("orb"+orbnum);
		if (orb is null) return;
		
		orb.ReloadSprite("MagicOrb.png", 8, 8, team, 0);
		orb.SetVisible(true);
		sprite.PlaySound("OrbFireSound.ogg", 1.3f, pitch);
	}
}

void RemoveOrb(CBlob@ this, const u8&in num, const bool&in dofire = true)
{
	CSpriteLayer@ orb = this.getSprite().getSpriteLayer("orb"+num);
	if (orb is null) return;
	
	orb.SetVisible(false);
	if (dofire)
		ParticleAnimated("FireFlash.png", this.getPosition() + orb.getOffset(), Vec2f(0, 0.5f), 0.0f, 1.0f, 2, 0.0f, true);
}

const f32 getMapCeiling(CMap@ map, const f32&in x)
{
	for (int i = 0; i < map.tilemapheight; i++)
	{
		if (!map.isTileSolid(map.getTile(Vec2f(x, i*8)))) return i*8;
	}
	return 0.0f;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	ParticleZombieLightning(this.getPosition()); //hack
}

void onDie(CBlob@ this)
{
	Sound::Play("EvilLaughShort1.ogg");
	ParticleTeleport(this.getPosition());
}
