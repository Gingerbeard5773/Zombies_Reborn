//metal hit effects

#include "ParticleSparks.as"

void ParticleMetalHit(Vec2f position, const f32&in damage, Vec2f velocity)
{
	if (!isClient()) return;

	const f32 volume = 0.5f + Maths::Min(damage * 0.5f, 0.5f);
	const f32 pitch = 0.85f + (XORRandom(100) / 1000.0f);
	Sound::Play("ShieldHit.ogg", position, volume, pitch);

	sparks(position, velocity.Angle(), 1);
}
