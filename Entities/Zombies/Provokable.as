f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isServer())
	{
		if (damage > 0.0f && hitterBlob !is null && !hitterBlob.hasTag("undead"))
		{
			//find damage player blob from projectiles
			CPlayer@ owner = hitterBlob.getDamageOwnerPlayer();
			if (hitterBlob.hasTag("projectile") && owner !is null)
			{
				CBlob@ damager = owner.getBlob();
				if (damager !is null)
				{
					this.getBrain().SetTarget(damager);
					return damage;
				}
			}
			
			this.getBrain().SetTarget(hitterBlob);
		}
	}
	return damage;
}
