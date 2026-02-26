// Gingerbeard @ July 11th, 2025

#include "BrainPath.as"
#include "Zombie_Translation.as"

#include "TaskAttack.as"
#include "TaskAssignment.as"
#include "TaskFuel.as"
#include "TaskFollow.as"
#include "TaskPath.as"
#include "TaskDeposit.as"
#include "TaskRefill.as"
#include "TaskTree.as"
#include "TaskGrain.as"
#include "TaskGather.as"
#include "TaskClass.as"
#include "TaskSafety.as"
#include "TaskGuard.as"
#include "TaskPatrol.as"
#include "TaskDorm.as"

enum Task
{
	Basic = 0,
	Path,
	Dorm,
	Factory,
	Library,
	Turret,
	Boat,
	Follow,
	Tree,
	Grain,
	Gather,
	Deposit,
	Fuel,
	Safety,
	Builder,
	Knight,
	Archer,
	Patrol,
	Guard,
	Refill
};

BrainTask@[] all_tasks;

void SetupTasksArray()
{
	all_tasks.clear();

	// Main tasks: Must be placed in same index as the correlating Task type 
	all_tasks.push_back(BrainTask(null));
	all_tasks.push_back(PathTask(null));
	all_tasks.push_back(DormTask(null));
	all_tasks.push_back(FactoryTask(null));
	all_tasks.push_back(LibraryTask(null));
	all_tasks.push_back(TurretTask(null));
	all_tasks.push_back(BoatTask(null));
	all_tasks.push_back(FollowTask(null));
	all_tasks.push_back(TreeTask(null));
	all_tasks.push_back(GrainTask(null));
	all_tasks.push_back(GatherTask(null));
	all_tasks.push_back(DepositTask(null));
	all_tasks.push_back(FuelTask(null));
	all_tasks.push_back(SafetyTask(null));
	all_tasks.push_back(ClassBuilderTask(null));
	all_tasks.push_back(ClassKnightTask(null));
	all_tasks.push_back(ClassArcherTask(null));
	all_tasks.push_back(PatrolTask(null));
	all_tasks.push_back(GuardTask(null));
	all_tasks.push_back(RefillTask(null));
	
	// Secondary tasks: Must be placed after all main tasks
	all_tasks.push_back(GatherWoodTask(null));
	all_tasks.push_back(GatherGrainTask(null));
}

class TaskManager
{
	CBlob@ blob;          // Blob utilizing this manager
	BrainTask@ standard;  // Base task used if no other tasks are used
	AttackTask@ attack;   // Blob attack behavior task
	BrainTask@ override;  // A 'temporary' task that overrides all other tasks in priority
	BrainTask@ previous;  // Task used in the previous tick
	BrainTask@[] tasks;   // Task array queue which holds each task in order
	u8 index;             // Index of the current task
	bool override_path;   // Used to override the basic path function.

	TaskManager(CBlob@ blob_)
	{
		@blob = blob_;
		blob.set("brain_task_manager", @this);

		@standard = BrainTask(blob);
		
		if (blob.getName() == "knight")
		{
			@attack = KnightAttackTask(blob);
		}
		else if (blob.getName() == "archer")
		{
			@attack = ArcherAttackTask(blob);
		}
		else
		{
			@attack = BuilderAttackTask(blob);
		}
	}

	void Tick()
	{
		BrainTask@ current = getCurrentTask();
		if (previous !is current)
		{
			if (previous !is null) previous.onUnsetTask();
			if (current !is null) current.onSetTask();
		}
		@previous = current;

		override_path = false;
		current.Tick();
		current.Path();
	}

	// Get the current task in queue, or the override if it is available
	BrainTask@ getCurrentTask()
	{
		if (override !is null) return override;

		if (index >= tasks.length) return standard;

		return tasks[index];
	}

	// Add a new task to the manager
	void AddTask(BrainTask@ task, const bool&in set_current = false)
	{
		for (int i = tasks.length - 1; i >= 0; i--)
		{
			if (tasks[i].solo) RemoveTask(i);
		}

		if (task.solo) tasks.clear();

		tasks.push_back(task);
		if (set_current || task.solo) index = tasks.length - 1;
	}

	// Set the override task
	void SetOverrideTask(BrainTask@ task)
	{
		@override = task;
	}

	// Set the next task in the queue to be the current task, removes the override task if it is applied
	void SetNextTask(const bool&in remove_current = false)
	{
		if (override !is null)
		{
			@override = null;
			return;
		}

		if (remove_current)
		{
			RemoveTask(index);
			return;
		}

		if (++index >= tasks.length) index = 0;
	}

	// Remove task at configured index
	void RemoveTask(const int&in remove_index)
	{
		tasks.erase(remove_index);
		if (remove_index <= index) index = Maths::Max(0, index - 1);
	}

	// Serialize entire manager to bit stream
	void Serialize(CBitStream@ stream)
	{
		stream.write_s32(index);
		stream.write_s32(tasks.length);
		for (int i = 0; i < tasks.length; i++)
		{
			tasks[i].Serialize(stream);
		}
	}

	// Read serialized bit stream to create manager copy
	bool Unserialize(CBitStream@ stream)
	{
		tasks.clear();

		if (!stream.saferead_s32(index)) return false;

		int tasks_length;
		if (!stream.saferead_s32(tasks_length)) return false;

		for (int i = 0; i < tasks_length; i++)
		{
			u8 type;
			if (!stream.saferead_u8(type)) return false;
			
			if (type >= all_tasks.length) return false;

			BrainTask@ task = all_tasks[type].Copy(blob);
			task.Unserialize(stream);
			tasks.push_back(task);
		}
		return true;
	}
}

class BrainTask 
{
	CBlob@ blob;            // Blob utilizing this task
	TaskManager@ manager;   // The task manager overseeing this task
	BrainPath@ pather;      // The blob's brain pather
	Vec2f destination;      // Destination to path to
	int path_refresh_rate;  // How often in ticks to refresh our path, -1 to disable pathing
	u8 type;                // Type of task
	string description;     // Description of task
	bool solo;              // Determines if the task can only be done solo (no other tasks permitted in queue)
	bool self;              // Determines if the task is from the selected migrant specifically

	// Custom data variables
	Vec2f origin;
	string target_name;
	u16 target_netid;

	/// Setup

	BrainTask(CBlob@ blob_)
	{
		@blob = blob_;

		path_refresh_rate = 80;
		type = Task::Basic;
		description = "Default";
		solo = false;
		self = false;

		if (blob !is null)
		{
			blob.get("brain_task_manager", @manager);
			blob.get("brain_path", @pather);
		}
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return BrainTask(blob_);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return false;
	}

	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		GUI::DrawIcon("TaskIcons.png", type, Vec2f(22, 22), pos, 1.0f, 0);
	}

	/// Events

	void Tick() // Called every tick
	{
		UseStandardOverrides();
	}

	void Path() // Tick pathing
	{
		if (destination == Vec2f_zero) return;

		if (blob.isAttached()) return;

		if (manager.override_path) return;

		if (path_refresh_rate <= 0 || getInterval() % path_refresh_rate != 0) return;

		if ((destination - blob.getPosition()).Length() >= pather.reach_high_level)
		{
			pather.SetPath(blob.getPosition(), destination);
		}
	}

	void onSetTask() // Called if this gets set as the current task
	{
		pather.EndPath();
	}

	void onUnsetTask() // Called if this is unset as the current task
	{
		destination = Vec2f_zero;
	}

	void onPathDestination() // Called if blob reaches its path destination 
	{
		// Override
	}

	/// Rendering

	void Render() // Rendering when in task-menu
	{
		if (origin == Vec2f_zero) return;

		int deltaY = -2 + Maths::FastSin(getGameTime() / 4.5f) * 3.0f;
		Driver@ driver = getDriver();
		Vec2f pos = driver.getScreenPosFromWorldPos((origin + Vec2f(0, -8)) + Vec2f(0, -16) * driver.getResolutionFactor());
		pos.y += deltaY;
		GUI::DrawIcon("InteractionIcons.png", 19, Vec2f(32, 32), pos, getCamera().targetDistance * driver.getResolutionScaleFactor());
	}

	/// Helper functions

	bool UseStandardOverrides()
	{
		if (getInterval() % 30 == 0)
		{
			if (OverrideWithDormTask()) return true;
		}

		manager.attack.AttackNearbyEnemies();
		manager.attack.AttackMovement();

		if (manager.attack.hasAttacker()) return true;

		return false;
	}

	bool OverrideWithDormTask(const f32&in health_percent = 0.75f)
	{
		if (blob.getHealth() > blob.getInitialHealth() * health_percent) return false;

		CBlob@ dorm = getClosestDorm();
		if (dorm is null) return false;

		DormTask@ task = DormTask(blob);
		manager.SetOverrideTask(task);
		return true;
	}

	CBlob@ getClosestDorm()
	{
		CBlob@[] dorms;
		if (!getBlobsByName("dorm", @dorms)) return null;

		CBlob@ closest = null;
		f32 closest_dist = 600.0f;

		for (u16 i = 0; i < dorms.length; i++)
		{
			CBlob@ dorm = dorms[i];
			const f32 dist = blob.getDistanceTo(dorm);
			if (dist < closest_dist && !dorm.hasAttached())
			{
				@closest = dorm;
				closest_dist = dist;
			}
		}
		return closest;
	}

	CBlob@[]@ getAttackers(const f32&in radius = 300.0f)
	{
		CBlob@[] attackers;
		CBlob@[] blobsInRadius;
		getMap().getBlobsInRadius(blob.getPosition(), radius, @blobsInRadius);

		for (u16 i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if ((!b.hasTag("undead") && !b.hasTag("skelepede")) || b.isAttached()) continue;

			if (!canSeeAttacker(b)) continue;

			attackers.push_back(b);
		}

		return @attackers;
	}

	bool canSeeAttacker(CBlob@ target)
	{
		Vec2f aimvec = target.getPosition() - blob.getPosition();
		HitInfo@[] hitinfos;
		getMap().getHitInfosFromRay(blob.getPosition(), -aimvec.Angle(), aimvec.Length(), null, hitinfos);
		for (u16 i = 0; i < hitinfos.length; i++)
		{
			CBlob@ b = hitinfos[i].blob;
			if (b is null) return false; //hit solid tile

			if (blob.isAttachedTo(b)) continue;

			if (b is target) return true;

			if (b.getShape().isStatic() && b.isCollidable() && !b.isPlatform()) return false;
		}
		return false;
	}

	u16 getBestTarget(const f32&in radius = 600)
	{
		u16 best_target = 0;
		f32 closest_dist = 600.0f;
		u8 highest_priority = 0;

		CBlob@[]@ attackers = getAttackers(radius);
		for (u16 i = 0; i < attackers.length; i++)
		{
			CBlob@ attacker = attackers[i];
			const f32 dist = blob.getDistanceTo(attacker);
			const u8 priority = getPriority(attacker);

			// If same priority, it must be closer
			// If higher priority, reset distance
			if (priority > highest_priority || (priority == highest_priority && dist < closest_dist))
			{
				best_target = attacker.getNetworkID();
				closest_dist = dist;
				highest_priority = priority;
			}
		}

		return best_target;
	}

	u8 getPriority(CBlob@ b)
	{
		if (b.hasTag("wraith")) return 255;
		if (b.hasTag("skelepede")) return 254;
		return 0;
	}

	bool isValidSpot(Vec2f position, const bool&in allow_water = true)
	{
		return pather.isGrounded(position) && (allow_water || !pather.isUnderwater(position));
	}

	Vec2f getStableGround(Vec2f position, const bool&in allow_water = true)
	{
		position = pather.alignToPathGrid(position);
		if (isValidSpot(position, allow_water)) return position;

		CMap@ map = getMap();
		f32 closestDistance = 999999.0f;
		Vec2f closestPos = position;

		for (int y = -4; y <= 4; y++)
		{
			for (int x = -4; x <= 4; x++)
			{
				Vec2f neighborPos = position + Vec2f(x * tilesize, y * tilesize);
				if (isPassable(neighborPos, map) && isValidSpot(neighborPos, allow_water))
				{
					const f32 distance = (neighborPos - position).LengthSquared();
					if (distance < closestDistance)
					{
						closestDistance = distance;
						closestPos = neighborPos;
					}
				}
			}
		}

		if (closestPos != position) return closestPos;

		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return position;

		HighLevelNode@[] nodes = getNodesInRadius(position, 8*16, nodeMap, Path::GROUND);
		for (int i = 0; i < nodes.length; i++)
		{
			HighLevelNode@ node = nodes[i];
			const f32 distance = (node.position - position).Length();
			if (distance < closestDistance && isValidSpot(node.position, allow_water))
			{
				closestPos = node.position;
				closestDistance = distance;
			}
		}

		return closestPos;
	}

	u32 getInterval()
	{
		return getGameTime() + blob.getNetworkID() * 33;
	}

	bool opEquals(BrainTask@ task)
	{
		return this is task;
	}

	// Serialize for synchronization
	void Serialize(CBitStream@ stream)
	{
		stream.write_u8(type);
		stream.write_Vec2f(destination);
		stream.write_Vec2f(origin);
		stream.write_string(target_name);
		stream.write_netid(target_netid);
	}

	// Unserialize for synchronization
	bool Unserialize(CBitStream@ stream)
	{
		if (!stream.saferead_Vec2f(destination))  return false;
		if (!stream.saferead_Vec2f(origin))       return false;
		if (!stream.saferead_string(target_name)) return false;
		if (!stream.saferead_netid(target_netid)) return false;
		return true;
	}
	
	// Serialize the task to a string for the map saver
	string SerializeString(u16[]@ saved_netids)
	{
		string data;
		data += type + ";";
		data += destination.x + ";" + destination.y + ";";
		data += origin.x + ";" + origin.y + ";";
		data += target_name + ";";

		const int target_index = saved_netids.find(target_netid);
		data += target_index + ";";
		return data;
	}

	// Unserialize the task from a string for the map saver
	void LoadFromString(const string[]@ data, CBlob@[]@ loaded_blobs)
	{
		destination.x = parseFloat(data[1]);
		destination.y = parseFloat(data[2]);
		origin.x = parseFloat(data[3]);
		origin.y = parseFloat(data[4]);

		target_name = data[5];
		
		const int target_index = parseInt(data[6]);
		CBlob@ target = target_index != -1 ? loaded_blobs[target_index] : null;
		if (target !is null)
		{
			target_netid = target.getNetworkID();
		}
	}
}


TaskManager@ getTaskManager(CBlob@ this)
{
	TaskManager@ manager;
	this.get("brain_task_manager", @manager);
	return manager;
}

BrainTask@ getCurrentTask(CBlob@ this)
{
	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return null;

	return manager.getCurrentTask();
}
