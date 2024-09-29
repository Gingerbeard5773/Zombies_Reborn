#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	//compensate for some damage hitters
	switch(customData)
	{
		case Hitters::ballista:
			damage *= 2.5f;
			break;
		case Hitters::cata_boulder:
			damage *= 2.0f;
			break;
		case Hitters::arrow:
		{
			//headshots deal additional damage
			const Vec2f headPoint = this.getPosition() - Vec2f(0, this.getRadius()/2);
			const bool hitHead = (worldPoint - headPoint).Length() < this.getRadius()/2;
			if (this.hasTag("dead") || hitHead)
			{
				ParticleBloodSplat(worldPoint, true);
				damage *= 1.5f;
			}
			break;
		}
		case Hitters::saw:
		{
			//damage saw if we were killed by one
			this.server_Hit(hitterBlob, hitterBlob.getPosition(), -velocity, Maths::Clamp(this.getHealth() / 3, 0.25f, 0.5f), Hitters::muscles, true);
			ParticleBloodSplat(worldPoint, true);
			break;
		}
	}
	
	//player controlled wraiths don't damage as much
	if (hitterBlob.getPlayer() !is null && hitterBlob.hasTag("exploding"))
	{
		damage *= 0.15f;
	}
	
	//damage without activating server_die- to allow for negative health
	this.Damage(damage, hitterBlob);
	
	//kill if health went below gibHealth
	if (this.getHealth() <= this.get_f32("gib health"))
	{
		this.getSprite().Gib();
		
		givePartialCoinsOnDeath(this);
		this.server_Die();
	}

	return 0.0f;
}

void givePartialCoinsOnDeath(CBlob@ this)
{
	const u16 coins = this.get_u16("coins on death");
	Vec2f floor_pos = this.getPosition() + Vec2f(0, -3.0f);
	if (coins <= 0) return;

	// drop 100% of coins to floor
	CPlayer@ player = this.getPlayerOfRecentDamage();
	if (player is null)
	{
		server_DropCoins(floor_pos, coins);
		return;
	}

	// drop 90% of coins to floor, give 10% to player
	const u16 coinsToDrop = Maths::Floor(coins * 0.90f);
	const u16 coinsLeft = coins - coinsToDrop;
	server_DropCoins(floor_pos, coinsToDrop);
	player.server_setCoins(player.getCoins() + coinsLeft);
}
