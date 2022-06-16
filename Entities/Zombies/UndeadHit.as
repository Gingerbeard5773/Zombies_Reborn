#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	//compensate for some damage hitters
	switch(customData)
	{
		case Hitters::ballista:
			damage *= 2.5; break;
		case Hitters::cata_boulder:
			damage *= 2; break;
		case Hitters::arrow:
			if (this.hasTag("dead")) damage *= 1.5; break;
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
