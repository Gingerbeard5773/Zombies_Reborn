//teleport effects

void ParticleTeleport(Vec2f&in pos)
{
	if (!isClient()) return;

	ParticleAnimated("Flash3.png", pos, Vec2f(0,0), float(XORRandom(360)), 1.0f, 3, 0.0f, true);
	Sound::Play("Teleport.ogg", pos, 0.8f, 1.0f);
	Sound::Play("Respawn.ogg", pos, 3.0f);
}

Random spark_random(12345);
void ParticleTeleportSparks(Vec2f pos, const u8&in amount, Vec2f push_vel)
{
	for (u8 i = 0; i < amount; i++)
	{
		Vec2f vel(spark_random.NextFloat() * 1.0f, 0);
		vel.RotateBy(spark_random.NextFloat() * 360.0f);
		vel += push_vel;

		SColor col(255, 180 + XORRandom(40), 0, 255);
		CParticle@ p = ParticlePixel(pos, vel, col, true);
		if (p is null) continue;

		p.collides = false;
		p.timeout = 10 + spark_random.NextRanged(20);
		//p.scale = 0.5f + spark_random.NextFloat();
		p.damping = 0.95f;
		p.gravity = Vec2f(0,0);
		p.Z = 650.0f;
	}
}

void ParticleTeleportSparks(Vec2f start_pos, Vec2f end_pos)
{
	if (!isClient()) return;

	Vec2f vec = end_pos - start_pos;
	Vec2f norm = vec;
	norm.Normalize();

	const int aim_length = vec.Length() - 32;
	for (int step = 0; step < aim_length; step += 8)
	{
		ParticleTeleportSparks(start_pos + norm * step, 3, norm * 4.0f);
	}
}

void ParticleTeleportLegacy(Vec2f&in pos)
{
	if (!isClient()) return;

	ParticleZombieLightning(pos);
	Sound::Play("Respawn.ogg", pos, 3.0f);
	
	for (u8 i = 0; i < 5; i++)
	{
		Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
		CParticle@ p = ParticleAnimated("MediumSteam", pos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, true);
		if (p !is null) p.Z = 650.0f;
	}
}
