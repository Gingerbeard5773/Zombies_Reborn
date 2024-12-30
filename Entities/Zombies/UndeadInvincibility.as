//temporary invincibility after spawning

const u16 INVINCIBILITY_TIME = 20;
const u16 NO_HIT_TIME = 90;

void onInit(CBlob@ this)
{
	this.Tag("invincible");
}
void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() < INVINCIBILITY_TIME) return;

	this.Untag("invincible");
	this.getCurrentScript().tickFrequency = 0;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.getTickSinceCreated() < NO_HIT_TIME) return 0.0f;

	return damage;
}
