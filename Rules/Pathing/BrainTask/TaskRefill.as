// Gingerbeard @ February 9th, 2026

#include "VehicleCommon.as"

class RefillTask : BrainTask
{
	string[] ammo_names;

	RefillTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_);
		description = Translate::TaskRefill;
		type = Task::Refill;

		VehicleInfo@ v;
		if (target is null || !target.get("VehicleInfo", @v)) return;

		origin = target.getPosition();
		target_name = target.getName();

		for (int i = 0; i < v.ammo_types.length; ++i)
		{
			ammo_names.push_back(v.ammo_types[i].ammo_name);
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return RefillTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() != "builder") return false;

		CInventory@ inv = selected.getInventory();
		if (inv !is null && !selected.hasTag("player") && selected.getTeamNum() == worker.getTeamNum()) 
		{
			VehicleInfo@ v;
			if (selected.get("VehicleInfo", @v) && v.ammo_types.length > 0)
			{
				return true;
			}
		}
		return false;
	}

	void DrawIcon(Vec2f pos, CBlob@ selected)
	{
		if (selected is null) return;
		
		string item_name;

		VehicleInfo@ v;
		if (ammo_names.length == 0)
		{
			if (!selected.get("VehicleInfo", @v)) return;

			item_name = v.ammo_types[0].ammo_name;
		}
		else
		{
			item_name = ammo_names[0];
		}

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

		Deposit();
	}

	void Deposit()
	{
		if (getInterval() % 50 != 0) return;

		CBlob@ ammo = null;
		CInventory@ inv = blob.getInventory();
		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			if (ammo_names.find(item.getName()) != -1)
			{
				@ammo = item;
				break;
			}
		}

		if (ammo is null)
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
			if (!closest.server_PutInInventory(ammo))
			{
				blob.server_PutInInventory(ammo);
			}
		}

		destination = closest.getPosition();
	}

	string SerializeString(u16[]@ saved_netids)
	{
		string data = BrainTask::SerializeString(@saved_netids);
		string ammos = "";
		for (int i = 0; i < ammo_names.length; i++)
		{
			if (i > 0) ammos += " ";
			ammos += ammo_names[i];
		}

		data += ammos + ";";
		return data;
	}

	void LoadFromString(const string[]@ data, CBlob@[]@ loaded_blobs)
	{
		BrainTask::LoadFromString(data, @loaded_blobs);

		ammo_names.clear();
		const string[]@ names = data[7].split(" ");

		for (int i = 0; i < names.length; i++)
		{
			ammo_names.push_back(names[i]);
		}
	}
}
