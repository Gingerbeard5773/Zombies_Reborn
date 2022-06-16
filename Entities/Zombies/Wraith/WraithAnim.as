void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("enraged"))
	{
		if (!this.isAnimation("attack"))
			this.SetAnimation("attack");
	}
	else if (!blob.isOnGround() && !blob.isOnLadder()) 
	{
		if (!this.isAnimation("fly"))
			this.SetAnimation("fly");
	}
	else if (!this.isAnimation("walk"))
			 this.SetAnimation("walk");
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) return;
	
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("exploding")) return;
	
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ RibCage  = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 0, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Rib1     = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 0, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Rib2     = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 0, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Bone1    = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp , 80),       0, 3, Vec2f (8,8), 2.0f, 0,  "/BodyGibFall", team);
	CParticle@ Bone2    = makeGibParticle("UndeadGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80),   0, 4, Vec2f (8,8), 2.0f, 0,  "/BodyGibFall", team);
}
