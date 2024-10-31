//temporary invincibility after spawning

const u16 INVINCIBILITY_TIME = 3 * 30;

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	const u32 created_tick = this.getTickSinceCreated();
	if (created_tick >= INVINCIBILITY_TIME)
	{
		if (created_tick >= INVINCIBILITY_TIME * 2) //latentcy reasons
			this.getCurrentScript().runFlags |= Script::remove_after_this;
		return damage;
	}
	
	return 0.0f;
}
