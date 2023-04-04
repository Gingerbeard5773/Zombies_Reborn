//temporary invincibility after spawning

const int INVINCIBILITY_SECONDS = 2;

void onInit(CBlob@ this)
{
	this.Tag("invincible");
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() >= INVINCIBILITY_SECONDS * getTicksASecond())
	{
		this.Untag("invincible");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f;
}
