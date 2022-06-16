void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	
	if (blob.hasTag("dead"))
	{
		if (!this.isAnimation("dead"))
		{
			this.SetAnimation("dead");
			this.animation.time = 0;
			this.PlaySound("/ZombieDie");
		}
		
		this.SetFrameIndex(blob.getVelocity().Length() > 1.0f ? 2 : 3);
		return;
	}
	
	if (!this.isAnimationEnded() && (this.isAnimation("attack") || this.isAnimation("revive"))) return;

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	
	if (blob.isOnLadder() && (up || down))
	{
		if (!this.isAnimation("jump"))
			 this.SetAnimation("jump");
	}
	else if (left || right)
	{
		if (!this.isAnimation("walk"))
			 this.SetAnimation("walk");
	}
	else
	{
		if (!this.isAnimation("default"))
			 this.SetAnimation("default");
	}
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) return;
	
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp , 80),       1, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm1     = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm2     = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp , 80),       1, 3, Vec2f (8,8), 2.0f, 0,  "/BodyGibFall", team);
	CParticle@ Sword    = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80),   1, 4, Vec2f (8,8), 2.0f, 0,  "/BodyGibFall", team);
}
