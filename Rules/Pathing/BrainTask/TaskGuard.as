// Gingerbeard @ February 9th, 2026

class GuardTask : BrainTask
{
	GuardTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskGuard;
		type = Task::Guard;
		path_refresh_rate = 30;
		solo = true;
		if (target !is null)
		{
			target_netid = target.getNetworkID();
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return GuardTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (selected !is getLocalPlayerBlob() && !selected.hasTag("migrant")) return false;
		if (worker is selected) return false;

		return worker.getName() == "knight" || worker.getName() == "archer";
	}
	
	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		const int frame = blob.getName() == "archer" ? 1 : 0; 
		GUI::DrawIcon("TaskGuardIcons.png", frame, Vec2f(22, 22), pos, 1.0f, 0);
	}
	
	void Tick()
	{
		manager.attack.AttackNearbyEnemies();
		
		if (StayCloseToProtectee())
		{
			manager.attack.AttackMovement();
		}
	}

	bool StayCloseToProtectee()
	{
		CBlob@ follow_target = getBlobByNetworkID(target_netid);
		if (follow_target !is null)
		{
			const f32 targetDistance = (follow_target.getPosition() - blob.getPosition()).Length();
			if (targetDistance > 200.0f) return false;
		}
		return true;
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

		const f32 scale = getCamera().targetDistance * getDriver().getResolutionScaleFactor() * 0.65f;
		Vec2f pos = target.getInterpolatedScreenPos() - Vec2f(32, 32*3 + target.getHeight()) * scale;
		GUI::DrawIcon("MenuItems.png", 31, Vec2f(32, 32), pos, scale);
	}
}
