
void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead")) //check dead
	{
		Vec2f vel = blob.getVelocity();
		this.SetAnimation("dead");
		this.SetOffset(Vec2f(0,1));

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		return;
	}

	// get facing
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	if (inair)
	{
		this.SetAnimation("fall");
		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		this.animation.timer = 0;

		if (vy < -1.5 || up)
		{
			this.animation.frame = 0;
		}
		else
		{
			this.animation.frame = 1;
		}
	}
	else if (left || right ||
	         (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		this.SetAnimation("default");
	}
}
