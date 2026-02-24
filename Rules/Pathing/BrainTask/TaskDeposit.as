// Gingerbeard @ February 9th, 2026

class DepositTask : BrainTask
{
	DepositTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskDeposit;
		type = Task::Deposit;
		if (target !is null)
		{
			origin = target.getPosition();
			target_name = target.getName();
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return DepositTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() != "builder") return false;

		CInventory@ inv = selected.getInventory();
		if (inv is null) return false;

		if (selected.getTeamNum() != worker.getTeamNum()) return false;

		if (selected.hasTag("player")) return false;

		if (selected.exists("packed") && selected.get_string("packed").size() > 0) return false;

		VehicleInfo@ v;
		if (selected.get("VehicleInfo", @v) && v.ammo_types.length > 0) return false;

		return true;
	}

	void Tick()
	{
		if (UseStandardOverrides()) return;

		Deposit();
	}

	void Deposit()
	{
		if (getInterval() % 50 != 0) return;

		CInventory@ inv = blob.getInventory();
		if (inv.getItem(0) is null)
		{
			manager.SetNextTask();
			return;
		}

		CBlob@ closest = null;
		f32 closest_dist = 200.0f;

		CBlob@[] blobs;
		getBlobsByName(target_name, @blobs);

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			Vec2f pos = b.getPosition();
			const f32 dist = (pos - origin).Length();
			if (dist >= closest_dist) continue;

			CInventory@ storage_inv = b.getInventory();
			if (storage_inv is null || storage_inv.isFull()) continue;

			if (!pather.canPath(blob.getPosition(), pos)) continue;

			@closest = b;
			closest_dist = dist;
		}

		if (closest is null)
		{
			manager.SetNextTask();
			return;
		}

		if (blob.getDistanceTo(closest) < closest.getRadius() * 2.0f || blob.isOverlapping(closest))
		{
			inv.server_MoveInventoryTo(closest.getInventory());
		}

		destination = closest.getPosition();
	}
}
