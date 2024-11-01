//temporary invincibility after spawning

const u16 INVINCIBILITY_TIME = 3 * 30;

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.getTickSinceCreated() < INVINCIBILITY_TIME) return 0.0f;

	return damage;
}
