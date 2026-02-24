// Gingerbeard @ February 9th, 2026

// todo: fix standard attachment points for client

class AssignmentTask : BrainTask
{
	u16 assigned_netid;

	AssignmentTask(CBlob@ blob_, CBlob@ assigned = null)
	{
		super(blob_);
		solo = true;
		if (assigned !is null)
		{
			assigned_netid = assigned.getNetworkID();
			origin = assigned.getPosition();
			target_name = assigned.getName();
		}
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return AssignmentTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		return selected.exists("maximum_worker_count") && hasAvailableWorkerSlots(selected);
	}

	void Tick()
	{
		if (UseStandardOverrides())
		{
			onUnsetTask();
			return;
		}

		if (getInterval() % 60 != 0) return;

		AttemptToAssign();
	}
	
	void AttemptToAssign()
	{
		CBlob@ assigned = getBlobByNetworkID(assigned_netid);
		if (assigned is null)
		{
			CBlob@[] blobs;
			getBlobsByName(target_name, @blobs);

			f32 closest_dist = 300.0f;

			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				Vec2f pos = b.getPosition();
				if ((pos - origin).Length() > 300.0f) continue;

				const f32 dist = (pos - blob.getPosition()).Length();
				if (dist >= closest_dist) continue;

				if (!hasAvailableWorkerSlots(b)) continue;

				if (!pather.canPath(blob.getPosition(), pos)) continue;

				@assigned = b;
				assigned_netid = assigned.getNetworkID();
				closest_dist = dist;
			}
		}

		if (assigned is null)
		{
			manager.SetNextTask(true);
			return;
		}
		
		destination = assigned.getPosition();

		if (!isOverlapping(assigned)) return;
		
		if (!hasAvailableWorkerSlots(assigned)) return;

		AssignWorker(assigned);
	}

	bool isOverlapping(CBlob@ assigned)
	{
		Vec2f tl1, br1, tl2, br2;
		blob.getShape().getBoundingRect(tl1, br1);
		assigned.getShape().getBoundingRect(tl2, br2);
		const bool overlapX = tl1.x <= br2.x && br1.x >= tl2.x;
		const bool overlapY = tl1.y <= br2.y && br1.y >= tl2.y;
		return overlapX && overlapY;
	}

	u16[]@ getWorkers(CBlob@ assigned)
	{
		u16[]@ netids;
		if (!assigned.get("assigned netids", @netids))
		{
			u16[] netids_;
			assigned.set("assigned netids", netids_);
			return netids_;
		}
		return netids;
	}

	bool isAssignedTo(CBlob@ assigned)
	{
		u16[]@ workers = getWorkers(assigned);
		const int index = workers.find(blob.getNetworkID());
		return index != -1;
	}
	
	bool hasAvailableWorkerSlots(CBlob@ assigned)
	{
		return getWorkers(assigned).length < assigned.get_u8("maximum_worker_count");
	}
	
	void AssignWorker(CBlob@ assigned)
	{
		u16[]@ workers = getWorkers(assigned);
		const int index = workers.find(blob.getNetworkID());
		if (index != -1) return;

		workers.push_back(blob.getNetworkID());
		assigned.set_u8("current_worker_count", workers.length);
		assigned.Sync("current_worker_count", true);

		onAssignWorker(assigned);
	}

	void UnassignWorker(CBlob@ assigned)
	{
		u16[]@ workers = getWorkers(assigned);
		const int index = workers.find(blob.getNetworkID());
		if (index == -1) return;
		
		workers.erase(index);
		assigned.set_u8("current_worker_count", workers.length);
		assigned.Sync("current_worker_count", true);

		onUnassignWorker(assigned);
	}

	void onAssignWorker(CBlob@ assigned)
	{
		AttachToWorkerSlot(assigned);
	}

	void onUnassignWorker(CBlob@ assigned)
	{
		blob.server_DetachFrom(assigned);
	}

	void AttachToWorkerSlot(CBlob@ assigned)
	{
		if (blob.isAttachedToPoint("WORKER")) return;

		AttachmentPoint@[] aps;
		if (!assigned.getAttachmentPoints(@aps)) return;

		for (u8 i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap.name != "WORKER" || ap.getOccupied() !is null) continue;

			assigned.server_AttachTo(blob, ap);
			break;
		}
	}

	void onUnsetTask()
	{
		destination = Vec2f_zero;

		CBlob@ assigned = getBlobByNetworkID(assigned_netid);
		if (assigned is null) return;

		UnassignWorker(assigned);
	}

	void onPathDestination()
	{
		AttemptToAssign();
	}
	
	string SerializeString(u16[]@ saved_netids)
	{
		string data = BrainTask::SerializeString(@saved_netids);
		const int assigned_index = saved_netids.find(assigned_netid);
		data += assigned_index + ";";
		return data;
	}

	void LoadFromString(const string[]@ data, CBlob@[]@ loaded_blobs)
	{
		BrainTask::LoadFromString(data, @loaded_blobs);

		const int assigned_index = parseInt(data[7]);
		CBlob@ assigned = assigned_index != -1 ? loaded_blobs[assigned_index] : null;
		if (assigned !is null)
		{
			assigned_netid = assigned.getNetworkID();
		}
	}
}


/// BUILDINGS

class FactoryTask : AssignmentTask
{
	FactoryTask(CBlob@ blob_, CBlob@ assigned = null)
	{
		super(blob_, assigned);
		description = Translate::TaskFactory;
		type = Task::Factory;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return FactoryTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (!AssignmentTask::isTaskBlob(selected, worker)) return false;

		return selected.getName() == "factory";
	}
}

class LibraryTask : AssignmentTask
{
	LibraryTask(CBlob@ blob_, CBlob@ assigned = null)
	{
		super(blob_, assigned);
		description = Translate::TaskLibrary;
		type = Task::Library;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return LibraryTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (!AssignmentTask::isTaskBlob(selected, worker)) return false;

		return selected.getName() == "library";
	}
}


/// TURRETS (cannons, ballistas, mounted bows)

class TurretTask : AssignmentTask
{
	TurretTask(CBlob@ blob_, CBlob@ assigned = null)
	{
		super(blob_, assigned);
		description = Translate::TaskTurret;
		type = Task::Turret;
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return TurretTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (!AssignmentTask::isTaskBlob(selected, worker)) return false;

		return selected.hasTag("turret");
	}

	void Tick()
	{
		if (getInterval() % 60 == 0)
		{
			AttemptToAssign();
		}

		blob.setKeyPressed(key_action1, false);

		CBlob@ assigned = getBlobByNetworkID(assigned_netid);
		if (assigned is null || !blob.isAttachedTo(assigned)) return;

		if (getInterval() % 10 == 0)
		{
			target_netid = getBestTarget();
		}

		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target !is null && target.getHealth() > target.get_f32("gib health"))
		{
			if (!getMap().rayCastSolidNoBlobs(blob.getPosition(), target.getPosition()))
				blob.setKeyPressed(key_action1, true);

			blob.setAimPos(target.getPosition());
		}
	}

	void onAssignWorker(CBlob@ assigned)
	{
		AttachmentPoint@ gun = assigned.getAttachments().getAttachmentPointByName("GUNNER");
		if (gun !is null && gun.getOccupied() is null)
		{
			assigned.server_AttachTo(blob, @gun);
		}
	}

	void onUnassignWorker(CBlob@ assigned)
	{
		assigned.server_DetachFrom(blob);
	}
}


/// BOAT

class BoatTask : AssignmentTask
{
	BoatTask(CBlob@ blob_, CBlob@ assigned = null)
	{
		super(blob_, assigned);
		description = Translate::TaskBoat;
		type = Task::Boat;
	}
	
	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return BoatTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (!AssignmentTask::isTaskBlob(selected, worker)) return false;

		return selected.getName() == "warboat" || selected.getName() == "longboat";
	}
	
	void Tick()
	{
		if (getInterval() % 60 != 0) return;

		AttemptToAssign();
	}

	void onAssignWorker(CBlob@ assigned)
	{
		AttachmentPoint@[] aps;
		if (!assigned.getAttachmentPoints(@aps)) return;

		for (u8 i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap.getOccupied() !is null || ap.name != "ROWER") continue;

			assigned.server_AttachTo(blob, @ap);
			break;
		}
	}

	void onUnassignWorker(CBlob@ assigned)
	{
		assigned.server_DetachFrom(blob);
	}
}
