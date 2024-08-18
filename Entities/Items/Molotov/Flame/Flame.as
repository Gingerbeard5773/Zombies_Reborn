#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.4f);
	
	this.server_SetTimeToDie(2 + XORRandom(3));
	this.getCurrentScript().tickFrequency = 15;
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 2;
	this.getCurrentScript().runFlags |= Script::tick_onscreen;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (this.isInWater()) this.server_Die();

	if (this.getTickSinceCreated() > 5) 
	{
		// getMap().server_setFireWorldspace(this.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), true);
		
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
	
		map.server_setFireWorldspace(pos, true);
		
		for (int i = 0; i < 3; i++)
		{
			Vec2f bpos = pos + Vec2f(12 - XORRandom(24), XORRandom(8));
			TileType t = map.getTile(bpos).type;
			map.server_setFireWorldspace(bpos, true);
		}
		CBlob@[] blobs;
		getMap().getBlobsInRadius(pos, this.getRadius()*3, blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) continue;
			if (map.rayCastSolidNoBlobs(pos, b.getPosition())) continue;
			
			else if (b.hasTag("flesh") || b.getShape().getConsts().isFlammable)
			{
				if (getGameTime() % 8 == 0)
				{
					this.server_Hit(b, pos, Vec2f(0, 0.33f), 0.6f, Hitters::fire, true);
				}
			}
		}
	}

}

void onTick(CSprite@ this)
{
	this.SetFrame(XORRandom(6));
	ParticleAnimated("SmallFire", this.getBlob().getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, 0), 0, 1.0f, 2, 0.25f, false);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getConfig() == this.getConfig() || (blob.isCollidable() && blob.getShape().isStatic());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if (solid) 
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();
		
			map.server_setFireWorldspace(pos, true);
			
			for (int i = 0; i < 3; i++)
			{
				Vec2f bpos = pos + Vec2f(12 - XORRandom(24), XORRandom(8));
				TileType t = map.getTile(bpos).type;
				if (map.isTileGround(t) && t != CMap::tile_ground_d0 && (XORRandom(100) < 50 ? true : t != CMap::tile_ground_d1))
				{
					map.server_DestroyTile(bpos, 1, this);
				}
				else
				{
					map.server_setFireWorldspace(bpos, true);
				}
			}
		}
		else if (blob !is null && blob.isCollidable())
		{
			if (this.getTeamNum() != blob.getTeamNum()) this.server_Hit(blob, this.getPosition(), Vec2f(), 0.0f, Hitters::fire, true);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isServer() && isWaterHitter(customData))
	{
		this.server_Die();
	}

	return damage;
}
