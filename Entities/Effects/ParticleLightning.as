// Lightning effects

Random lightning_random(0x10002);

void DrawLightningSegment(Vec2f start_pos, Vec2f end_pos, const int&in segments, const f32&in randomness, Random@ rand)
{
	Vec2f dir = end_pos - start_pos;
	const f32 dir_length = dir.Length();
	dir.Normalize();

	Vec2f perp(-dir.y, dir.x);
	Vec2f prev = start_pos;

	for (int i = 1; i <= segments; i++)
	{
		const f32 t = i / f32(segments);
		Vec2f point = start_pos + dir * (dir_length * t);

		// offset except for endpoints
		if (i != segments)
		{
			const f32 offset = (rand.NextRanged(100) / 100.0f - 0.5f) * randomness;
			point += perp * offset;
		}

		ParticleLightning(prev, point);
		prev = point;
	}
}

void ParticleLightning(Vec2f start_pos, Vec2f end_pos)
{
	if (!isClient()) return;

	Vec2f vec = end_pos - start_pos;
	Vec2f norm = vec;
	norm.Normalize();

	const int distance = vec.Length();
	for (int step = 0; step < distance; step += 1.5f)
	{
		ParticleLightning(start_pos + norm * step);
	}
}

void ParticleLightning(Vec2f pos)
{
	Vec2f vel(lightning_random.NextFloat() * 0.25f, 0);
	vel.RotateBy(lightning_random.NextFloat() * 360.0f);

	SColor col(50, 255, 255, 255);
	CParticle@ p = ParticlePixelUnlimited(pos, vel, color_white, true);
	if (p !is null)
	{
		p.setRenderStyle(RenderStyle::additive);
		p.timeout = 6 + lightning_random.NextRanged(10);
		p.collides = false;
		p.gravity = Vec2f_zero;
		p.damping = 0.94f;
		p.Z = 660.0f;
	}
}

void ParticleLightningSparks(Vec2f pos, const int&in amount)
{
	if (!isClient()) return;

	for (int i = 0; i < amount; i++)
	{
		Vec2f vel(lightning_random.NextFloat() * 4.0f, 0);
		vel.RotateBy(lightning_random.NextFloat() * 360.0f);

		SColor col = SColor(255, 200 + lightning_random.NextRanged(55), 200 + lightning_random.NextRanged(55), 255);
		CParticle@ p = ParticlePixel(pos, vel, col, true);
		if (p is null) return;

		p.fastcollision = true;
		p.gravity = Vec2f(0.0f,0.1f);
		p.timeout = 20 + lightning_random.NextRanged(20);
		p.scale = 1.0f + lightning_random.NextFloat();
		p.damping = 0.95f;
	}
}
