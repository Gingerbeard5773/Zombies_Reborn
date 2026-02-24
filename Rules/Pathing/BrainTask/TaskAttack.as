// Gingerbeard @ February 9th, 2026

// Attacking behavior for specific classes
// These are not standard 'tasks' since they are only used in other tasks in tandem.

#include "KnightCommon.as"
#include "ArcherCommon.as"
#include "UndeadAttackCommon.as"

class AttackTask : BrainTask
{
	u32 attack_time;
	u32 shield_time;
	u16 attacker_netid;

	AttackTask(CBlob@ blob_)
	{
		super(blob_);
	}

	void DetectNearbyEnemies()
	{
		if (getInterval() % 30 == 0)
		{
			attacker_netid = getBestTarget(400.0f);
		}
	}

	bool hasAttacker()
	{
		return attacker_netid != 0;
	}

	void AttackNearbyEnemies()
	{
		DetectNearbyEnemies();
		Attack();
	}
	
	void Attack()
	{
	
	}

	void AttackMovement()
	{
		
	}

	void Runaway()
	{
		if (blob.isAttached()) return;

		if (pather.isPathing() && (destination - blob.getPosition()).Length() < pather.reach_high_level * 3)
		{
			pather.EndPath();
			return;
		}
		
		if (path_refresh_rate >= 0 && (!pather.isPathing() || getInterval() % path_refresh_rate == 0))
		{
			destination = getSafestNodePosition();

			pather.SetPath(blob.getPosition(), destination);
		}
	}

	Vec2f getSafestNodePosition(const f32 radius = 200.0f)
	{
		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null) return blob.getPosition();

		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return blob.getPosition();

		HighLevelNode@[] nodes = getNodesInRadius(blob.getPosition(), radius, nodeMap, Path::GROUND);

		Vec2f best_pos = blob.getPosition();
		f32 best_score = -1;

		for (u32 i = 0; i < nodes.length; i++)
		{
			HighLevelNode@ node = nodes[i];
			const f32 score = (node.position - target.getPosition()).Length();
			if (score > best_score)
			{
				best_score = score;
				best_pos = node.position;
			}
		}

		return best_pos;
	}

	/// Brain Common

	void Flee(CBlob@ target)
	{
		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);
		if (target.getPosition().x > blob.getPosition().x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}
	}

	void Chase(CBlob@ target)
	{
		Vec2f mypos = blob.getPosition();
		Vec2f targetPos = target.getPosition();
		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);
		if (targetPos.x < mypos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (targetPos.y + getMap().tilesize < mypos.y)
		{
			blob.setKeyPressed(key_up, true);
		}
	}
	
	void JumpOverObstacles()
	{
		Vec2f pos = blob.getPosition();
		const f32 radius = blob.getRadius();

		if (blob.isOnWall())
		{
			blob.setKeyPressed(key_up, true);
		}
		else if (!blob.isOnLadder())
		{
			if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
					(blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
			{
				blob.setKeyPressed(key_up, true);
			}
		}
	}
}

class BuilderAttackTask : AttackTask
{
	BuilderAttackTask(CBlob@ blob_)
	{
		super(blob_);
	}

	void Attack()
	{
		
	}
	
	void AttackMovement()
	{
		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null) return;
		
		manager.override_path = true;

		Runaway();

		//Flee(target);
		//JumpOverObstacles();
	}
}

class KnightAttackTask : AttackTask
{
	KnightAttackTask(CBlob@ blob_)
	{
		super(blob_);
	}

	void Attack()
	{
		blob.setKeyPressed(key_action2, false);
		blob.setKeyPressed(key_action1, false);

		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null) return;

		KnightInfo@ knight;
		if (!blob.get("knightInfo", @knight)) return;

		Vec2f mypos = blob.getPosition();
		Vec2f targetPos = target.getPosition();
		const f32 targetDistance = (targetPos - mypos).Length();

		// aim always at enemy
		blob.setAimPos(targetPos);
		
		if (targetDistance < 80.0f)
		{
			blob.setKeyPressed(key_action1, true);

			if (targetDistance < 40.0f)
			{
				const f32 target_health = target.getHealth() - (target.exists("gib health") ? target.get_f32("gib health") : 0);
				if (knight.swordTimer > KnightVars::slash_charge || (knight.swordTimer > 2 && target_health < 0.5f))
				{
					blob.setKeyPressed(key_action1, false);
				}
			}
		}

		const u32 gametime = getGameTime();
		bool shieldTime = gametime - shield_time < uint(15 * 1.33f + XORRandom(20));

		UndeadAttackVars@ attack;
		if (target.get("attackVars", @attack) && attack.damage >= 1.25f)
		{
			const bool defensive = !target.hasTag("dead") && target.getHealth() > 1.0f && targetDistance < 60.0f && target.getBrain().getTarget() is blob;
			if (gametime + 20 >= attack.next_attack && defensive)
			{
				int r = XORRandom(35);
				if (r < 20)
				{
					shield_time = gametime;
					shieldTime = true;
				}
			}
		}

		if (shieldTime || (target.hasTag("exploding") && targetDistance < 160.0f)) // hold shield
		{
			blob.setKeyPressed(key_action2, true);
			blob.setKeyPressed(key_action1, false);
		}
	}

	void AttackMovement()
	{
		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null) return;

		manager.override_path = true;

		const f32 targetDistance = (target.getPosition() - blob.getPosition()).Length();
		if (target.hasTag("exploding") && targetDistance < 160.0f)
		{
			Flee(blob);
		}
		else if (targetDistance > blob.getRadius() + 15.0f)
		{
			Chase(target);
		}

		JumpOverObstacles();
	}
}

class ArcherAttackTask : AttackTask
{
	ArcherAttackTask(CBlob@ blob_)
	{
		super(blob_);
	}

	void Attack()
	{
		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null)
		{
			blob.setKeyPressed(key_action2, true);
			blob.setKeyPressed(key_action1, false);
			return;
		}

		ArcherInfo@ archer;
		if (!blob.get("archerInfo", @archer)) return;

		Vec2f mypos = blob.getPosition();
		Vec2f targetPos = target.getPosition();
		const f32 targetDistance = (targetPos - mypos).Length();

		blob.setKeyPressed(key_action2, false);
		blob.setKeyPressed(key_action1, true);

		const int full_shot = 25;
		const int triple_shot = 89;

		int charge_type = full_shot;
		const f32 target_health = target.getHealth() - (target.exists("gib health") ? target.get_f32("gib health") : 0);
		if (targetDistance < 80.0f && target_health > 0.5f)
		{
			charge_type = triple_shot;
		}

		if (archer.charge_time > charge_type + attack_time || archer.charge_state == ArcherParams::legolas_ready)
		{
			blob.setKeyPressed(key_action1, false);
			attack_time = XORRandom(10);
		}

		blob.setAimPos(getBallisticAimPos(target, archer.arrow_type));
	}

	void AttackMovement()
	{
		CBlob@ target = getBlobByNetworkID(attacker_netid);
		if (target is null) return;

		manager.override_path = true;

		const f32 runDistance = target.hasTag("exploding") ? 160.0f : 80.0f;
		const f32 targetDistance = (target.getPosition() - blob.getPosition()).Length();
		if (targetDistance < runDistance && !target.hasTag("dead"))
		{
			Flee(blob);
		}

		JumpOverObstacles();
	}

	Vec2f getBallisticAimPos(CBlob@ target, const u8&in arrow_type)
	{
		Vec2f aimPos = target.getPosition();
		if (arrow_type == ArrowType::firework) return aimPos;

		if ((blob.getPosition() - aimPos).Length() < 200.0f) return aimPos;

		for (int i = 0; i < 12; i++)
		{
			if (isArrowTrajectoryValid(aimPos, target)) return aimPos;
			aimPos.y -= 8.0f;
		}
		return target.getPosition();
	}

	bool isArrowTrajectoryValid(Vec2f aimPos, CBlob@ target)
	{
		CMap@ map = getMap();
		const f32 interval = 25.0f;
		Vec2f targetPos = target.getPosition();
		const f32 targetRadius = target.getRadius();
		Vec2f offset(blob.isFacingLeft() ? 2 : -2, -2);
		Vec2f arrowPos = blob.getPosition() + offset;
		Vec2f vel = (aimPos - arrowPos);
		vel.Normalize();
		vel *= ArcherParams::shoot_max_vel;

		const int steps = 30; // how many steps ahead to simulate

		Vec2f pos = arrowPos;
		for (int i = 0; i < steps; i++)
		{
			const f32 gravity = i > 14 ? 7 * 0.2f : 0.1f;
			const f32 t = interval / 30.0f; // seconds per step (assuming 30 ticks/sec)
			pos += vel * t + Vec2f(0, gravity * 0.5f * t * t);
			vel.y += gravity * t;

			if (map.isTileSolid(pos)) return false;

			if (Maths::Abs(pos.x - targetPos.x) <= targetRadius+8.0f && Maths::Abs(pos.y - targetPos.y) <= targetRadius) return true;

			//CParticle@ p = ParticlePixel(pos, Vec2f_zero, SColor(255, 255, 0, 0), true, 1);
			//p.gravity = Vec2f_zero;
		}
		return false;
	}
}
