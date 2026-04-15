// scroll script that shows the range of the scroll via little arrows

void onInit(CBlob@ this)
{
	if (!isClient()) return;
	
	const int indicator_count = Maths::Max(4, this.get_f32("scroll_range") / 16);

	CSprite@ sprite = this.getSprite();
	for (int i = 0; i < indicator_count; i++)
	{
		CSpriteLayer@ layer = sprite.addSpriteLayer("indicator_"+i, "GUI/PartyIndicator.png", 16, 16, 5, 0);
		if (layer is null) continue;

		Animation@ anim = layer.addAnimation("default", 0, false);
		anim.AddFrame(2);
		layer.SetVisible(false);
		layer.SetHUD(true);
	}
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	if (!this.isAttached()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null || !holder.isMyPlayer()) return;

	const bool visible = holder.isKeyPressed(key_use) && !getHUD().hasMenus();

	const f32 range = this.get_f32("scroll_range");
	const int indicator_count = Maths::Max(4, range / 16);

	CSprite@ sprite = this.getSprite();
	for (int i = 0; i < indicator_count; i++)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer("indicator_" + i);
		if (layer is null) continue;

		const f32 time = getGameTime() * 100.0f / range;
		const f32 angle = time + (360.0f * i) / indicator_count;

		Vec2f offset(range, 0);
		offset.RotateBy(angle);
		layer.SetOffset(offset);

		layer.ResetTransform();
		layer.RotateBy(offset.getAngleDegrees() - 90, Vec2f_zero);

		layer.SetVisible(visible);
		layer.SetFacingLeft(false);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (!isClient()) return;

	const int indicator_count = Maths::Max(4, this.get_f32("scroll_range") / 16);

	CSprite@ sprite = this.getSprite();
	for (int i = 0; i < indicator_count; i++)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer("indicator_" + i);
		if (layer is null) continue;

		layer.SetVisible(false);
	}
}
