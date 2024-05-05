// Zombie Portal

#include "MakeScroll.as";

const f32 activation_radius = 100;
u16 maximum_zombies = 400;

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-50); //background
	sprite.getConsts().accurateLighting = true;
	CSpriteLayer@ portal = sprite.addSpriteLayer("portal", "ZombiePortal.png" , 64, 64, 3, -1);
	portal.SetFrame(1);
	portal.SetRelativeZ(1000);
	
	CShape@ shape = this.getShape();
	shape.getConsts().mapCollisions = false;
	
	//kill overlapped buildings
	CBlob@[] buildings;
	if (getBlobsByTag("building", buildings))
	{
		Vec2f mypos = this.getPosition();
		Vec2f myhalfsize = Vec2f(shape.getWidth(), shape.getHeight()) * 0.5f;
		for (uint i = 0; i < buildings.length; ++i)
		{
			CBlob@ building = buildings[i];

			CShape@ theirshape = building.getShape();
			if (theirshape is null) continue;

			Vec2f theirpos = building.getPosition();
			Vec2f theirhalfsize = Vec2f(theirshape.getWidth(), theirshape.getHeight()) * 0.5f;

			Vec2f dif = Vec2f(Maths::Abs(theirpos.x - mypos.x), Maths::Abs(theirpos.y - mypos.y));
			Vec2f totalsize = theirhalfsize + myhalfsize;

			Vec2f sep = totalsize - dif;
			//aabb check
			if (sep.x > 2 && sep.y > 2)
			{
				building.server_Die();
				break;
			}
		}
	}
	
	this.set_TileType("background tile", CMap::tile_castle_back_moss);
	this.Tag("builder always hit");
	this.Tag("building");
	
	this.SetLightRadius(64.0f);
	if (!this.isLight())
		this.SetLight(false);
	
	this.addCommandID("client_activate_portal");
	
	if (isServer())
	{
		ConfigFile cfg;
		if (cfg.loadFile("Zombie_Vars.cfg"))
		{
			maximum_zombies = cfg.exists("maximum_zombies") ? cfg.read_u16("maximum_zombies") : 400;
		}
		
		if (this.hasTag("portal_activated"))
		{
			this.SetLight(true);
			this.SendCommand(this.getCommandID("client_activate_portal"));
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.hasTag("portal_activated"))
	{
		const int spawnRate = 18 + (190 * this.getHealth() / 44.0);
		if (getGameTime() % spawnRate == 0 && getRules().get_u16("undead count") <= maximum_zombies)
		{
			Vec2f pos = this.getPosition();
			ParticleZombieLightning(pos);
			
			if (isServer())
			{
				const u32 r = XORRandom(100);
		
				string blobname = "skeleton"; //leftover       // 40%
				
				if (r >= 90)       blobname = "wraith";        // 10%
				else if (r >= 75)  blobname = "zombieknight";  // 15%
				else if (r >= 40)  blobname = "zombie";        // 35%
				
				server_CreateBlob(blobname, -1, pos);
			}
		}
	}
	else 
	{
		if (isServer())
		{
			//check if players are within bounds to activate the portal
			const u8 playerCount = getPlayerCount();
			for (u8 i = 0; i < playerCount; i++)
			{
				CPlayer@ ply = getPlayer(i);
				if (ply is null) continue;
				
				CBlob@ plyBlob = ply.getBlob();
				if (plyBlob !is null && !plyBlob.hasTag("undead") && plyBlob.getDistanceTo(this) <= activation_radius)
				{
					this.SetLight(true);
					this.Tag("portal_activated");
					this.SendCommand(this.getCommandID("client_activate_portal"));
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null && hitterBlob.hasTag("undead")) return 0.0f;
	
	return damage;
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("WoodDestruct.ogg", 1.2f, 0.7f);
	
	if (isServer())
	{
		server_DropCoins(this.getPosition() + Vec2f(0, -8.0f), 1000);

		//make a random scroll
		ScrollSet@ all = getScrollSet("all scrolls");
		if (all !is null)
		{
			server_MakePredefinedScroll(this.getPosition(), all.names[XORRandom(all.names.length)]);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_activate_portal"))
	{
		this.getSprite().PlaySound("PortalBreach");
		this.SetLight(true);
		this.Tag("portal_activated");
	}
}
