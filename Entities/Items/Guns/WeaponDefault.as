// Weapon default

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (this.hasTag("gun") && !attached.hasTag("weapon cursor") && attached.hasTag("player"))
	{
		attached.getSprite().AddScript("WeaponCursor.as");
		attached.Tag("weapon cursor");
	}

	this.getShape().getConsts().isFlammable = false;

	this.Tag("invincible");
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (this.exists("burn timer"))
	{
		this.getShape().getConsts().isFlammable = true;
	}

	this.Untag("invincible");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible")) return 0.0f;

	return damage;
}
