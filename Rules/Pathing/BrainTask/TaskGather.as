// Gingerbeard @ February 9th, 2026

class GatherTask : BrainTask
{
	GatherTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskGather;
		type = Task::Gather;
		if (target !is null)
		{
			origin = target.getPosition();
			target_name = target.getName();
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return GatherTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (selected.getShape().isStatic()) return false;

		if (selected.hasTag("player") || selected.hasTag("projectile") || selected.hasTag("unpackall")) return false;

		if (!worker.isInventoryAccessible(selected)) return false;

		return selected.canBePutInInventory(worker);
	}

	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		if (selected is null) return;

		const string item_name = !target_name.isEmpty() ? target_name : selected.getName();
		const string icon = "$" + item_name + "$";

		Vec2f dim;
		GUI::GetIconDimensions(icon, dim);
		const f32 offset_x = Maths::Clamp(16 - dim.x, -dim.x, dim.x);
		const f32 offset_y = Maths::Clamp(16 - dim.y, -dim.y, dim.y);
		Vec2f offset(offset_x, offset_y);

		GUI::DrawIconByName(icon, pos + offset + Vec2f(8, 8), 1.0f);
	}

	void Tick()
	{
		if (UseStandardOverrides()) return;

		if (Collect()) return;

		SetTarget();
	}

	bool Collect()
	{
		if (getInterval() % 15 != 0) return false;

		CInventory@ inv = blob.getInventory();
		if (inv !is null && inv.isFull())
		{
			manager.SetNextTask();
			return true;
		}

		CBlob@[] blobs;
		getBlobsByName(target_name, @blobs);

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b.isAttached() || b.isInInventory()) continue;

			if ((b.getPosition() - blob.getPosition()).Length() > 20.0f) continue;

			blob.server_PutInInventory(b);
		}

		return false;
	}

	void SetTarget()
	{
		if (getInterval() % 50 != 0) return;

		CBlob@[] blobs;
		getBlobsByName(target_name, @blobs);

		CBlob@ closest = null;
		f32 closest_dist = 99999.0f;

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			Vec2f pos = b.getPosition();
			if (b.isAttached() || b.isInInventory()) continue;

			if ((pos - origin).Length() > 400.0f) continue;

			const f32 dist = (pos - blob.getPosition()).Length();
			if (dist >= closest_dist) continue;

			if (!pather.canPath(blob.getPosition(), pos)) continue;

			@closest = b;
			closest_dist = dist;
		}

		if (closest is null)
		{
			manager.SetNextTask();
			return;
		}

		destination = closest.getPosition();
	}
}

class GatherWoodTask : GatherTask
{
	GatherWoodTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_, target);
		target_name = "mat_wood";
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return GatherWoodTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return selected.getName() == "log" || selected.hasTag("tree");
	}

	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		target_name = "mat_wood";
		GatherTask::DrawIcon(pos, selected);
	}
}

class GatherGrainTask : GatherTask
{
	GatherGrainTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_, target);
		target_name = "grain";
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return GatherGrainTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return selected.getName() == "grain_plant";
	}
	
	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		target_name = "grain";
		GatherTask::DrawIcon(pos, selected);
	}
}
