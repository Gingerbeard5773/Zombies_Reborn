//undead gib effects

void UndeadGibs(CSprite@ this, const string&in filename, u8&in frames_count = 5)
{
	if (g_kidssafe) return;

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;

	const f32 health = blob.getHealth() - blob.get_f32("gib health");
	const f32 magnitude = Maths::Min(Maths::Abs(health), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();

	const u16 undead_count = getRules().get_u16("undead count");
	const u8 gibs_amount = frames_count - Maths::Min(undead_count / 75, frames_count - 1);
	u8 frame = XORRandom(frames_count);
	for (u8 i = 0; i < gibs_amount; ++i)
	{
		UndeadGib(filename, pos, vel, magnitude, frame, team);
		frame++;
		frame %= frames_count;
	}
}

CParticle@ UndeadGib(const string&in filename, Vec2f pos, Vec2f vel, const f32&in magnitude, const u8&in frame, const u8&in team)
{
	return makeGibParticle(filename, pos, vel + getRandomVelocity(90, magnitude, 80), 0, frame, Vec2f(8, 8), 2.0f, 0, "/BodyGibFall", team);
}
