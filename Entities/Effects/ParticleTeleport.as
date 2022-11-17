//teleport effects

void ParticleTeleport(Vec2f&in pos)
{
	if (isClient())
	{
		ParticleZombieLightning(pos);
		Sound::Play("Respawn.ogg", pos, 3.0f);
		
		for (u8 i = 0; i < 5; i++)
		{
			Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
			ParticleAnimated("MediumSteam", pos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, true);
		}
	}
}
