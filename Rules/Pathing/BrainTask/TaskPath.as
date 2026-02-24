// Gingerbeard @ February 9th, 2026

class PathTask : BrainTask
{
	PathTask(CBlob@ blob_, Vec2f destination = Vec2f_zero)
	{
		super(blob_);
		this.destination = destination;
		description = Translate::TaskPath;
		type = Task::Path;
		self = true;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return PathTask(blob_);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return true;
	}

	void Tick()
	{
		origin = destination;

		if (UseStandardOverrides()) return;

		if (getInterval() % 60 == 0)
		{
			if ((blob.getPosition() - destination).Length() <= pather.reach_high_level * 2)
			{
				manager.SetNextTask();
				return;
			}
		}

		if (getInterval() % 300 != 0) return;

		if (destination != Vec2f_zero) destination = getStableGround(destination);
	}

	void onUnsetTask()
	{
		// Do not reset destination
	}

	void onPathDestination()
	{
		manager.SetNextTask();
	}
}
