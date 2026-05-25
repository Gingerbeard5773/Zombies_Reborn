// Enchanter animations

void onInit(CSprite@ this)
{
	for (int i = 0; i < 2; i++)
	{
		CSpriteLayer@ layer = this.addSpriteLayer("magic_coin_"+i, "coins.png", 16, 16);
		Animation@ spin = layer.addAnimation("spin", 2, true);
		int[] frames = { 3, 9, 15 };
		spin.AddFrames(frames);
		layer.RotateBy(90, Vec2f_zero);
		layer.SetAnimation(spin);
		layer.SetVisible(false);
		layer.SetIgnoreParentFacing(true);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	// get facing
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	if (blob.isKeyPressed(key_action1) || blob.get_u32("enchanting_time") > 0)
	{
		this.SetAnimation("fire");
	}
	else if (inair)
	{
		this.SetAnimation("fall");
		this.animation.timer = 0;

		const bool upwards = blob.getVelocity().y < -1.5 || up;
		this.animation.frame = upwards ? 0 : 1;
	}
	else if (left || right || (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		//look at player when nearby
		CBlob@ localBlob = getLocalPlayerBlob();
		if (localBlob !is null)
		{
			Vec2f pos = blob.getPosition();
			Vec2f localPos = localBlob.getPosition();
			if ((localPos - pos).Length() < 70.0f && !getMap().rayCastSolid(pos, localPos))
			{
				blob.SetFacingLeft(localPos.x < pos.x);
			}
		}

		this.SetAnimation("default");
	}

	HandleMagicCoins(blob, this);
}

void HandleMagicCoins(CBlob@ blob, CSprite@ this)
{
	AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("ENCHANT");
	if (point is null) return;

	CBlob@ item = point.getOccupied();

	for (int i = 0; i < 2; i++)
	{
		CSpriteLayer@ layer = this.getSpriteLayer("magic_coin_" + i);
		if (layer is null) continue;

		const f32 time = getGameTime() * 2.0f;
		const f32 angle = time + (i * 180.0f);

		Vec2f offset(12, 0);
		offset.RotateBy(angle);

		Vec2f pos = point.offset + offset;
		layer.SetOffset(pos);

		Vec2f dir = point.offset - pos;
		layer.ResetTransform();
		layer.RotateBy(dir.getAngleDegrees(), Vec2f_zero);

		layer.SetVisible(item !is null);
		layer.SetFacingLeft(false);
	}
}
