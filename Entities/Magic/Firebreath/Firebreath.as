#include "Hitters.as"
#include "ParticleBlast.as"
#include "ParticleMagic.as"

void onInit(CBlob@ this)
{
	this.set_u8("boom_num", 0);
	this.getShape().SetGravityScale(0);
	this.getShape().SetStatic(true);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("FireBlastLoop.ogg");
	sprite.SetEmitSoundVolume(0.95f);
	sprite.SetEmitSoundPaused(false);

	CParticle@ p = ParticleAnimated("Swirl.png", this.getPosition(), Vec2f_zero, f32(XORRandom(360)), 1.0f, 3, 0.0f, true);
	if (p !is null)
	{
		p.scale = 0.6f;
		p.Z = 200.0f;
	}
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

	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f direction = this.get_Vec2f("boom_direction");
	Vec2f distance = direction * (dist_const*1.5f);
	Vec2f boom_pos = pos + distance;

	if (this.getTickSinceCreated() % 3 == 0)
	{
		if (isServer())
		{
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(boom_pos, dist_const / 1.5f, @blobsInRadius);

			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ blob = blobsInRadius[i];
				if (this.getTeamNum() == blob.getTeamNum()) continue;

				Vec2f blob_pos = blob.getPosition();
				if (!canRaycast(map, blob, pos, blob_pos)) continue;

				Vec2f hit_vec = blob_pos - pos;
				hit_vec.Normalize();

				this.server_Hit(blob, blob_pos, hit_vec, 0.15f, Hitters::fire, true);
				this.server_Hit(blob, blob_pos, hit_vec, 0.15f, Hitters::bomb, true);
			}

			const int radius = boom_num * 0.75f;
			const f32 radsq = radius * 8 * radius * 8;

			for (int x_step = -radius; x_step < radius; ++x_step)
			{
				for (int y_step = -radius; y_step < radius; ++y_step)
				{
					Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
					if (off.LengthSquared() > radsq) continue;

					if (XORRandom(2) == 0) continue;

					Vec2f tile_pos = boom_pos + off;
					Vec2f hit_pos = tile_pos;
					map.rayCastSolid(pos, tile_pos, hit_pos);

					map.server_setFireWorldspace(hit_pos, true);
				}
			}
		}

		this.set_u8("boom_num", boom_num + 1);
	}

	if (isClient())
	{
		if (this.getTickSinceCreated() % 4 == 0)
		{
			Sound::Play("FireBlast" + (9+XORRandom(3)), boom_pos, 1.0f, 1.4f);
		}

		const int amount = Maths::Max(f32(boom_num) * 0.75f, 2);
		for (int i = 0; i < amount; i++)
		{
			Vec2f random = Vec2f(XORRandom(dist_const/1.7f)+1, 0).RotateByDegrees(XORRandom(361));
			Vec2f particle_pos = boom_pos + random;

			if (map.rayCastSolid(pos, particle_pos)) continue;

			ParticleBlastSmall(particle_pos, 2);
		}
	}
}

bool canRaycast(CMap@ map, CBlob@ blob, Vec2f start_pos, Vec2f blob_pos)
{
	const f32 radius = blob.getRadius() * 0.9f;
	Vec2f top = blob_pos + Vec2f(0, radius);
	Vec2f bottom = blob_pos + Vec2f(0, -radius);

	if (!map.rayCastSolid(start_pos, blob_pos)) return true;
	if (!map.rayCastSolid(start_pos, top))      return true;
	if (!map.rayCastSolid(start_pos, bottom))   return true;

	return false;
}
