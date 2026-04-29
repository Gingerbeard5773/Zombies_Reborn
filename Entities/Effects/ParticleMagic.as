// Magic effects

Random magic_random(12345);

/*void ParticleEnergyVortex(Vec2f pos, const f32&in radius = 40.0f, SColor col = color_white)
{
	if (!isClient()) return;

	const f32 angle = magic_random.NextRanged(360) * 3.14159f / 180.0f;
	const f32 dist =  magic_random.NextRanged(100) / 100.0f * radius;
	Vec2f spawn_pos = pos + Vec2f(Maths::Cos(angle), Maths::Sin(angle)) * dist;

	Vec2f dir = pos - spawn_pos;
	const f32 dist_to_center = dir.Length();
	dir.Normalize();
	const f32 speed = dist_to_center * 0.1f;
	Vec2f vel = dir * speed;

	const u8 c = 220 + magic_random.NextRanged(36);
	SColor adjusted_color(255, c, c, c);
	CParticle@ p = ParticlePixelUnlimited(spawn_pos, vel, adjusted_color, true);
	if (p !is null)
	{
		p.timeout = 20 + magic_random.NextRanged(10);
		p.collides = false;
		p.gravity = Vec2f_zero;
		p.damping = 0.94f;
		p.Z = 660.0f;
	}
}*/

void ParticleEnergyVortex(Vec2f pos, const f32&in radius = 40.0f, SColor col = color_white)
{
	if (!isClient()) return;

	const f32 angle = magic_random.NextRanged(360) * 3.14159f / 180.0f;
	const f32 dist =  magic_random.NextRanged(100) / 100.0f * radius;
	Vec2f spawn_pos = pos + Vec2f(Maths::Cos(angle), Maths::Sin(angle)) * dist;

	Vec2f dir = pos - spawn_pos;
	const f32 dist_to_center = dir.Length();
	dir.Normalize();
	const f32 speed = dist_to_center * 0.1f;
	Vec2f vel = dir * speed;

	const u8 rand = magic_random.NextRanged(36);
	const u8 r = Maths::Max(col.getRed() - 35, 0) + rand;
	const u8 g = Maths::Max(col.getGreen() - 35, 0) + rand;
	const u8 b = Maths::Max(col.getBlue() - 35, 0) + rand;
	SColor adjusted_color(col.getAlpha(), r, g, b);
	CParticle@ p = ParticlePixelUnlimited(spawn_pos, vel, adjusted_color, true);
	if (p !is null)
	{
		p.timeout = 20 + XORRandom(10);
		p.collides = false;
		p.gravity = Vec2f_zero;
		p.damping = 0.94f;
		p.Z = 660.0f;
	}
}

void ParticleCasterLine(Vec2f start_pos, Vec2f end_pos, SColor col = color_white)
{
	if (!isClient()) return;

	Vec2f dir = end_pos - start_pos;
	const f32 dist = dir.Length();
	Vec2f norm = dir;
	norm.Normalize();

	for (int i = 0; i < dist; i += 2)
	{
		Vec2f vel(magic_random.NextFloat() * 1.0f, 0);
		vel.RotateBy(magic_random.NextFloat() * 360.0f);
		vel += norm*2.0f;

		CParticle@ p = ParticlePixelUnlimited(start_pos + norm*i, vel, col, true);
		if (p is null) continue;

		p.collides = false;
		p.timeout = 5 + magic_random.NextRanged(5);
		p.damping = 0.95f;
		p.gravity = Vec2f(0, 0);
		p.Z = 650.0f;
	}
}

void ParticleMagicCircleVanish(Vec2f pos, const f32&in radius, SColor col = color_white)
{
	if (!isClient()) return;

	const int count = Maths::Max(6, int(radius * 3.0f));

	for (int i = 0; i < count; i++)
	{
		f32 angle = magic_random.NextFloat() * 360.0f;
		f32 r = radius * Maths::Sqrt(magic_random.NextFloat());

		Vec2f offset(r, 0);
		offset.RotateBy(angle);

		Vec2f spawnPos = pos + offset;

		Vec2f vel = offset;
		if (vel.LengthSquared() > 0)
		{
			vel.Normalize();
			vel *= 1.0f + magic_random.NextFloat() * 1.5f;
		}

		CParticle@ p = ParticlePixelUnlimited(spawnPos, vel, col, true);
		if (p is null) continue;

		p.collides = false;
		p.timeout = 10 + magic_random.NextRanged(20);
		p.damping = 0.92f;
		p.gravity = Vec2f(0, 0);
		p.Z = 650.0f;
	}
}

CParticle@ ParticleMagic(Vec2f pos, const string&in file_name)
{
	Vec2f vel(magic_random.NextFloat() * 1.0f, 0);
	vel.RotateBy(magic_random.NextFloat() * 360.0f);

	CParticle@ p = ParticleAnimated(file_name, pos, vel, f32(XORRandom(360)), 1.0f, 2 + XORRandom(4), 0.0f, true);
	if (p !is null)
	{
		p.scale = 0.45f + magic_random.NextFloat()*0.5f;
		p.damping = 0.85f;
		p.Z = 200.0f;
	}

	return p;
}
