// Gingerbeard @ February 9th, 2026

//todo: implement running

class DormTask : BrainTask
{
	DormTask(CBlob@ blob_)
	{
		super(blob_);
		description = Translate::TaskDorm;
		type = Task::Dorm;
		path_refresh_rate = 80;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return DormTask(blob_);
	}

	void Tick()
	{
		manager.attack.AttackNearbyEnemies();

		if (getInterval() % 30 != 0) return;

		CBlob@ dorm = getClosestDorm();
		if (isHealed() || dorm is null)
		{
			manager.SetNextTask();
			return;
		}

		destination = dorm.getPosition();
	}

	bool isHealed()
	{
		return blob.getHealth() >= blob.getInitialHealth();
	}
}
