// Gingerbeard @ February 9th, 2026

class FollowTask : BrainTask
{
	FollowTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskFollow;
		type = Task::Follow;
		path_refresh_rate = 30;
		solo = true;
		target_netid = target is null ? 0 : target.getNetworkID();
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return FollowTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (selected !is getLocalPlayerBlob() && !selected.hasTag("migrant")) return false;

		return worker !is selected;
	}

	void Tick()
	{
		origin = destination;

		manager.attack.AttackNearbyEnemies();

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

	void Path()
	{
		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target is null || target.hasTag("dead"))
		{
			manager.SetNextTask(true);
			return;
		}

		destination = target.getPosition();

		if (blob.isAttached()) return;
		
		if (manager.override_path) return;

		if ((destination - blob.getPosition()).Length() < pather.reach_high_level * 3)
		{
			pather.EndPath();
			return;
		}

		if (path_refresh_rate >= 0 && (!pather.isPathing() || getInterval() % path_refresh_rate == 0))
		{
			pather.SetPath(blob.getPosition(), destination);
		}
	}
	
	void Render()
	{
		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target is null) return;

		const f32 scale = getCamera().targetDistance * getDriver().getResolutionScaleFactor();
		Vec2f pos = target.getInterpolatedScreenPos() - Vec2f(16.5f, 46 + target.getHeight()) * scale;
		GUI::DrawIcon("GUI/PartyIndicator.png", 6, Vec2f(16, 16), pos, scale);
	}
}
