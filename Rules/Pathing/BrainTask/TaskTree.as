// Gingerbeard @ February 9th, 2026

#include "TreeCommon.as"

class TreeTask : BrainTask
{
	TreeTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskTree;
		type = Task::Tree;
		origin = target is null ? Vec2f_zero : target.getPosition();
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return TreeTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() != "builder") return false;

		return selected.hasTag("tree") || selected.getName() == "log";
	}

	void Tick()
	{
		if (UseStandardOverrides()) return;

		SetTarget();
		ChopStuff();
	}

	void SetTarget()
	{
		if (getInterval() % 50 != 0) return;

		destination = Vec2f_zero;

		CBlob@[] blobs;
		getBlobsByTag("tree", @blobs);
		getBlobsByName("log", @blobs);

		CBlob@ closest = null;
		f32 closest_dist = 99999.0f;

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b.isAttached() || b.isInInventory()) continue;

			Vec2f pos = b.getPosition();
			if ((pos - origin).Length() > 300.0f) continue;

			const f32 dist = (pos - blob.getPosition()).Length();
			if (dist >= closest_dist) continue;

			TreeVars vars;
			if (b.get("TreeVars", vars))
			{
				if (vars.grown_times < 10 && !b.hasTag("startbig")) continue;
			}
			
			if (b.exists("cut_down_time")) continue;

			if (!pather.canPath(blob.getPosition(), pos)) continue;

			@closest = b;
			closest_dist = dist;
		}

		if (closest is null)
		{
			manager.SetNextTask();
			return;
		}

		target_netid = closest.getNetworkID();
		destination = closest.getPosition();
	}

	void ChopStuff()
	{
		blob.setKeyPressed(key_action2, false);

		if (getInterval() % 30 != 0) return;

		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target is null) return;

		if (blob.getDistanceTo(target) > 20.0f) return;

		blob.setAimPos(target.getPosition());
		blob.setKeyPressed(key_action2, true);

		blob.server_Hit(target, target.getPosition(), target.getPosition() - blob.getPosition(), 0.75f, 13);

		if (target.getName() == "log")
		{
			CBlob@ b = server_CreateBlobNoInit("mat_wood");
			if (b !is null)
			{
				b.Tag("custom quantity");
				b.Init();

				b.setPosition(target.getPosition());
				b.setVelocity(Vec2f(0, -3.0f));
				b.server_SetQuantity(10);
			}
		}
	}
}
