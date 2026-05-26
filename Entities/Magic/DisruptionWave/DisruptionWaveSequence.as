//Disruption Wave Spell Event Sequence
//Unimplemented atm

#include "Hitters.as"

const int CAST_TIME = 25;

void onInit(CBlob@ this)
{
	this.set_u32("disruption_wave_start", getGameTime());
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	const int timeElapsed = getGameTime() - this.get_u32("disruption_wave_start");

	Vec2f pos = this.getPosition();
	Vec2f aim_vec = this.get_Vec2f("disruption_wave_direction");
	Vec2f norm = aim_vec;
	norm.Normalize();

	if (timeElapsed < CAST_TIME)
	{
		this.setVelocity(Vec2f(0, 0));

		const u16 takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_taunts | key_pickup;
		this.DisableKeys(takekeys);
		this.DisableMouse(true);

		if (getGameTime() % 8 == 0)
		{
			ParticleDisruptionSpark(this.getPosition());
		}
	}
	else if (timeElapsed >= CAST_TIME)
	{
		if (isServer())
		{
			CBlob@ orb = server_CreateBlob("disruptionwave");
			if (orb !is null)
			{
				orb.SetDamageOwnerPlayer(this.getPlayer());
				orb.setPosition(pos);
				orb.server_setTeamNum(this.getTeamNum());
				orb.set_Vec2f("boom_direction", norm);
			}

			CBlob@[] blobsInRadius;
			getMap().getBlobsInRadius(pos + norm * 4.0f, 8.0f, @blobsInRadius);

			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (this.getTeamNum() == b.getTeamNum()) continue;

				Vec2f hit_vec = b.getPosition() - pos;
				hit_vec.Normalize();

				this.server_Hit(b, b.getPosition(), hit_vec * 8.0f, 2.0f, Hitters::water, true);
			}
		}

		this.DisableKeys(0);
		this.DisableMouse(false);
	}
}

void ParticleDisruptionSpark(Vec2f pos)
{
	if (!isClient()) return;

	Vec2f random = Vec2f(XORRandom(5)-2, XORRandom(5)-2);
	Vec2f newPos = pos + random;

	CParticle@ p = ParticleAnimated("DisruptionSpark.png", newPos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true);
	if (p !is null)
	{
		p.Z = 1.0f;
		p.bounce = 0.0f;
		p.fastcollision = true;
		p.gravity = Vec2f_zero;
	}
}
