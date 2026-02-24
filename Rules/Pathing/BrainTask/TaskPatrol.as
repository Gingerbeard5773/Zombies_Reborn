// Gingerbeard @ February 9th, 2026

class PatrolTask : BrainTask
{
	PatrolTask(CBlob@ blob_, Vec2f destination = Vec2f_zero)
	{
		super(blob_);
		description = Translate::TaskPatrol;
		type = Task::Patrol;
		self = true;
		this.destination = destination;
		path_refresh_rate = 80;
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return PatrolTask(blob_);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return worker.getName() == "knight" || worker.getName() == "archer";
	}

	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		const int frame = blob.getName() == "archer" ? 1 : 0; 
		GUI::DrawIcon("TaskPatrolIcons.png", frame, Vec2f(22, 22), pos, 1.0f, 0);
	}

	void Tick()
	{
		if (getInterval() % 300 == 0 && destination != Vec2f_zero)
		{
			destination = getStableGround(destination, false);
		}
		
		manager.attack.AttackNearbyEnemies();
		manager.attack.AttackMovement();

		if (getInterval() % 30 != 0) return;

		origin = destination;

		if (OverrideWithDormTask(0.25f)) return;

		if ((blob.getPosition() - destination).Length() <= pather.reach_high_level * 2 && !manager.attack.hasAttacker())
		{
			manager.SetNextTask();
			return;
		}
	}

	void onUnsetTask()
	{
		// Do not reset destination
	}
}
