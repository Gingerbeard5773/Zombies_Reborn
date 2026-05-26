#include "Hitters.as"
#include "LimitedAttacks.as"
#include "KnockedCommon.as"
#include "UndeadKnockedCommon.as"
#include "ParticleMagic.as"
#include "ParticleBlast.as"
#include "ParticleLightning.as"

const u8 maximum_chains = 10;
const f32 arc_size = 180.0f;
const f32 arc_distance = 10.0f * 8.0f;

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;

	this.getSprite().PlaySound("Lightning.ogg", 5.0f);

	this.server_SetTimeToDie(2);

	LimitedAttack_setup(this);

	Vec2f[] chain_positions;
	this.set("chain_positions", chain_positions);
}

void onTick(CBlob@ this)
{
	Vec2f[]@ chain_positions;
	if (!this.get("chain_positions", @chain_positions)) return;

	if (chain_positions.length == 0)
	{
		chain_positions.push_back(this.getPosition());
	}

	if (chain_positions.length >= maximum_chains) return;

	CMap@ map = getMap();
	const f32 angle = this.getAngleDegrees();
	Vec2f current_chain_pos = chain_positions[chain_positions.length - 1];

	bool hit = false;
	HitInfo@[] hitInfos;
	map.getHitInfosFromArc(current_chain_pos, angle, arc_size, arc_distance, this, true, @hitInfos);
	
	for (int i = 0; i < hitInfos.length; i++)
	{
		CBlob@ blob = hitInfos[i].blob;
		if (blob is null) continue;

		if (!isHittable(blob) || blob.getTeamNum() == this.getTeamNum()) continue;
		
		if (LimitedAttack_has_hit_actor(this, blob)) continue;

		LimitedAttack_add_actor(this, blob);

		Vec2f blob_pos = blob.getPosition();
		Vec2f hit_vec = blob_pos - current_chain_pos;
		hit_vec.Normalize();

		chain_positions.push_back(blob_pos);

		Sound::Play("LightningImpact"+XORRandom(3), blob_pos);
		ParticleLightningSparks(blob_pos, 10);

		if (isServer())
		{
			this.server_Hit(blob, blob_pos, hit_vec, 2.0f, Hitters::bomb, true);

			if (isKnockable(blob))
			{
				setKnocked(blob, 120, true);

				blob.Tag("dazzled");
				blob.Sync("dazzled", true);
			}

			if (isUndeadKnockable(blob))
			{
				setUndeadKnocked(blob, 150, true);
			}
		}

		hit = true;

		break;
	}

	Random rand(this.getNetworkID() * 33 + chain_positions.length);

	// if no blobs hit, just add a random direction to go towards
	if (!hit)
	{
		const f32 random_angle = angle - (45) + rand.NextRanged(91);
		Vec2f direction = Vec2f(1, 0).RotateBy(random_angle);
		Vec2f hit_pos = current_chain_pos + direction * arc_distance;

		if (map.rayCastSolid(current_chain_pos, hit_pos, hit_pos))
		{
			Sound::Play("LightningImpact"+XORRandom(3), hit_pos);
			ParticleLightningSparks(hit_pos, 10);
		}

		chain_positions.push_back(hit_pos - direction * 4.0f);
	}

	// lightning effects
	if (isClient() && chain_positions.length > 1)
	{
		Vec2f next_chain_position = chain_positions[chain_positions.length - 1];

		// main bolt
		DrawLightningSegment(current_chain_pos, next_chain_position, 6, 6.0f, rand);

		// extra faint branches
		for (int i = 0; i < 2; i++)
		{
			DrawLightningSegment(current_chain_pos, next_chain_position, 6, 10.0f, rand);
		}
	}
}

bool isHittable(CBlob@ blob)
{
	return blob.hasTag("flesh") || blob.hasTag("undead") || blob.hasTag("skelepede");
}
