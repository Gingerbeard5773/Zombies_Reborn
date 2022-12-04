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
	if (hitterBlob.getPlayer() !is null && hitterBlob.hasTag("enraged"))
	{
		damage *= 0.15f;
	}
	
	//damage without activating server_die- to allow for negative health
	this.Damage(damage, hitterBlob);
	
	//kill if health went below gibHealth
	if (this.getHealth() <= this.get_f32("gib health"))
	{
		this.getSprite().Gib();
		
		server_DropCoins(this.getPosition() + Vec2f(0, -3.0f), this.get_u16("coins on death"));
		this.server_Die();
	}

	return 0.0f;
}
