// Gingerbeard @ February 9th, 2026

#include "GetSurvivors.as"

class SafetyTask : BrainTask
{
	u32 seed;

	SafetyTask(CBlob@ blob_, const u32&in seed = 1)
	{
		super(blob_);
		description = Translate::TaskSafety;
		type = Task::Safety;
		solo = true;
		this.seed = seed;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return SafetyTask(blob_);
	}

	void Tick()
	{
		if (UseStandardOverrides()) return;

		if (getInterval() % 150 == 0 || destination == Vec2f_zero)
		{
			destination = getDestination();
			origin = destination;
		}

		if (getInterval() % 60 == 0)
		{
			if ((blob.getPosition() - destination).Length() <= pather.reach_high_level * 2)
			{
				manager.SetNextTask(true);
				return;
			}
		}
	}

	Vec2f getDestination()
	{
		Vec2f offset(16 - XORRandom(32), 0);

		//choose random building
		CBlob@[] buildings;
		if (getBlobsByTag("building", @buildings))
		{
			return buildings[seed % buildings.length].getPosition() + offset;
		}
		
		Vec2f pos = blob.getPosition();
		Vec2f closest_pos = pos;
		f32 closest_dist = 99999.0f;

		CBlob@[] survivors = getSurvivors();
		for (int i = 0; i < survivors.length; i++)
		{
			CBlob@ survivor = survivors[i];
			
			const f32 dist = (pos - survivor.getPosition()).Length();
			if (dist >= closest_dist) continue;

			closest_dist = dist;
			closest_pos = survivor.getPosition();
		}

		return closest_pos + offset;
	}
	
	string SerializeString(u16[]@ saved_netids)
	{
		string data = BrainTask::SerializeString(@saved_netids);
		data += seed + ";";
		return data;
	}

	void LoadFromString(const string[]@ data, CBlob@[]@ loaded_blobs)
	{
		BrainTask::LoadFromString(data, @loaded_blobs);
		seed = parseInt(data[7]);
	}
}
