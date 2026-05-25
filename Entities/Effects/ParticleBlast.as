// Particle blast

Random blast_random(0x10002);

void ParticleBlast(Vec2f pos, const int&in amount = 1)
{
	if (!isClient()) return;

	for (int i = 0; i < amount; i++)
	{
		Vec2f vel(blast_random.NextFloat() * 2.0f, 0);
		vel.RotateBy(blast_random.NextFloat() * 360.0f);

		CParticle@ p = ParticleAnimated("GenericBlast6.png", pos, vel, f32(XORRandom(360)), 1.0f, 1 + XORRandom(4), 0.0f, true);
		if (p is null) continue;

		p.fastcollision = true;
		p.scale = 0.5f + blast_random.NextFloat()*0.5f;
		p.damping = 0.85f;
		p.Z = 300.0f;
		p.lighting = false;
	}
}

void ParticleBlastBig(Vec2f pos, const int&in amount = 1)
{
	if (!isClient()) return;

	for (int i = 0; i < amount; i++)
	{
		Vec2f vel(blast_random.NextFloat() * 6.0f, 0);
		vel.RotateBy(blast_random.NextFloat() * 360.0f);

		CParticle@ p = ParticleAnimated("GenericBlast5.png", pos, vel, f32(XORRandom(360)), 1.0f, 1 + XORRandom(4), 0.0f, true);
		if (p is null) continue;

		p.fastcollision = true;
		p.scale = 0.45f + blast_random.NextFloat()*0.5f;
		p.damping = 0.85f;
		p.Z = 300.0f;
	}
}

void ParticleBlastSmall(Vec2f pos, const int&in amount = 1)
{
	if (!isClient()) return;

	for (int i = 0; i < amount; i++)
	{
		Vec2f vel(blast_random.NextFloat() * 1.0f, 0);
		vel.RotateBy(blast_random.NextFloat() * 360.0f);

		Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * 4.0f;
		CParticle@ p = ParticleAnimated("RocketFire1.png", pos + random, vel, f32(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, true);
		if (p is null) continue;

		p.bounce = 0;
		p.fastcollision = true;
		p.Z = 301.0f;
	}
}
