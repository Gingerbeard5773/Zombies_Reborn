#include "Hitters.as";
#include "Zombie_TechnologyCommon.as";

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
		case Hitters::sword:
			damage *= getSwordDamagePercent();
			break;
		case Hitters::builder:
		{
			if (hasTech(Tech::CombatPickaxes))
				damage *= 2.0f;
		}
		case Hitters::burn:
		case Hitters::fire:
		{
			if (hasTech(Tech::GreekFire))
				damage *= 1.5f;
		}
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
	
	if (isExplosionHitter(customData) || customData == Hitters::keg)
	{
		damage *= getExplosionDamagePercent();
	}
	
	CPlayer@ player = this.getPlayer();
	if (player !is null && customData == Hitters::suicide)
	{
		if (isServer())
		{
			this.server_SetPlayer(null);
			this.getBrain().server_SetActive(true);
		}
		if (player.isMyPlayer())
		{
			getHUD().ClearMenus();
			player.client_RequestSpawn();
		}
		return 0.0f;
	}
	
	//player controlled wraiths don't damage as much
	if (hitterBlob.getPlayer() !is null && hitterBlob.hasTag("exploding"))
	{
		damage *= 0.15f;
	}
	
	//damage without activating server_die- to allow for negative health
	this.Damage(damage, hitterBlob);
	
	//kill if health went below gibHealth
	if (this.getHealth() <= this.get_f32("gib health") && !this.hasTag("died"))
	{
		this.getSprite().Gib();
		server_givePartialCoinsOnDeath(this, worldPoint);
		this.server_Die();
		this.Tag("died");
	}

	return 0.0f;
}

void server_givePartialCoinsOnDeath(CBlob@ this, Vec2f&in drop_pos)
{
	if (!isServer()) return;

	const u16 coins = this.get_u16("coins on death");
	if (coins <= 0) return;

	// drop 100% of coins to floor
	CPlayer@ player = this.getPlayerOfRecentDamage();
	if (player is null)
	{
		server_DropCoins(drop_pos, coins);
		return;
	}

	// drop 90% of coins to floor, give 10% to player
	const u16 coinsToDrop = Maths::Floor(coins * getCoinDropPercent());
	const u16 coinsLeft = coins - coinsToDrop;
	server_DropCoins(drop_pos, coinsToDrop);
	player.server_setCoins(player.getCoins() + coinsLeft);
}

f32 getExplosionDamagePercent()
{
	f32 percent = 1.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Shrapnel))    percent += 0.25f;
	if (hasTech(TechTree, Tech::ShrapnelII))  percent += 0.25f;
	return percent;
}

f32 getSwordDamagePercent()
{
	f32 percent = 1.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Swords))    percent += 0.25f;
	if (hasTech(TechTree, Tech::SwordsII))  percent += 0.25f;
	return percent;
}

f32 getCoinDropPercent()
{
	f32 percent = 1.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Coinage))    percent -= 0.10f;
	if (hasTech(TechTree, Tech::CoinageII))  percent -= 0.10f;
	if (hasTech(TechTree, Tech::CoinageIII)) percent -= 0.10f;
	return percent;
}
