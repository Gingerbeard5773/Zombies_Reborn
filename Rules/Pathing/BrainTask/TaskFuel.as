// Gingerbeard @ February 9th, 2026

#include "FuelCommon.as"

class FuelTask : BrainTask
{
	FuelTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskFuel;
		type = Task::Fuel;
		if (target !is null)
		{
			origin = target.getPosition();
			target_name = target.getName();
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return FuelTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() != "builder") return false;

		return selected.getName() == "quarry" || selected.getName() == "forge";
	}

	void Tick()
	{
		if (UseStandardOverrides()) return;

		SetTarget();
		Fuel();
	}

	void SetTarget()
	{
		if (getInterval() % 50 != 0) return;

		const int index = getFuelIndex(blob);
		if (index == -1)
		{
			manager.SetNextTask();
			return;
		}

		CBlob@ closest = null;
		f32 closest_dist = 400.0f;

		CBlob@[] blobs;
		getBlobsByName(target_name, @blobs);

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			Vec2f pos = b.getPosition();
			const f32 dist = (pos - origin).Length();
			if (dist >= closest_dist) continue;

			if (b.get_s16(fuel_prop) + 100 >= max_fuel) continue;

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

	void Fuel()
	{
		if (getInterval() % 30 != 0) return;

		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target is null) return;

		if (blob.getDistanceTo(target) > target.getRadius()) return;
		
		if (target.get_s16(fuel_prop) >= max_fuel) return;

		server_addFuel(target, blob);
	}
}
