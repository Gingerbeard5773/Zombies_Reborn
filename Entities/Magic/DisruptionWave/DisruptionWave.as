#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.set_u8("boom_num", 0);
	this.getShape().SetGravityScale(0);

	this.getSprite().PlaySound("continuous_explosion.ogg", 3.0f, 1.5f);
	this.getShape().SetStatic(true);
}

void onTick(CBlob@ this)
{
	const u8 boom_num = this.get_u8("boom_num");
	if (boom_num >= 10)
	{
		this.server_Die();
		return;
	}

	const f32 dist_const = 8.0f * boom_num;

	Vec2f pos = this.getPosition();
	Vec2f distance = this.get_Vec2f("boom_direction") * (dist_const*1.5f);
	Vec2f boom_pos = pos + distance;

	if (this.getTickSinceCreated() % 4 == 0)
	{
		CBlob@[] blobsInRadius;
		getMap().getBlobsInRadius(boom_pos, dist_const / 1.5f, @blobsInRadius);

		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (this.getTeamNum() == b.getTeamNum()) continue;

			Vec2f hit_vec = b.getPosition() - pos;
			hit_vec.Normalize();

			this.server_Hit(b, b.getPosition(), hit_vec * 6.0f, 1.4f, Hitters::water, true);
		}

		this.set_u8("boom_num", boom_num + 1);
	}

	if (isClient())
	{
		for (u8 i = 0; i < 2; i++)
		{
			Vec2f random = Vec2f(XORRandom(dist_const/1.7f)+1, 0).RotateByDegrees(XORRandom(361));
			Vec2f particle_pos = boom_pos + random;
			ParticleDisruptionSpark(particle_pos);
		}

		if (XORRandom(3) == 2)
		{
			Vec2f random = Vec2f(XORRandom(dist_const/1.7f)+1, 0).RotateByDegrees(XORRandom(361));
			Vec2f particle_pos = boom_pos + random;
			ParticleShockwave(particle_pos);
			Sound::Play("individual_boom.ogg", particle_pos, 3.0f);
		}
	}
}

void ParticleDisruptionSpark(Vec2f pos)
{
	if (!isClient()) return;

	CParticle@ p = ParticleAnimated("DisruptionSpark.png", pos, Vec2f_zero, XORRandom(361), 0.8f, 1, 0.0f, true);
	if (p !is null)
	{
		p.Z = 500.0f;
		p.collides = false;
		p.gravity = Vec2f_zero;
	}
}

void ParticleShockwave(Vec2f pos)
{
	if (!isClient()) return;

	CParticle@ p = ParticleAnimated("Shockwave3.png", pos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true);
	if (p !is null)
	{
		p.Z = 500.0f;
		p.collides = false;
		p.gravity = Vec2f_zero;
	}
}
