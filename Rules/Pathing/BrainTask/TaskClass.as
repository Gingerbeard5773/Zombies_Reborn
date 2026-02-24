// Gingerbeard @ February 9th, 2026

class ClassTask : BrainTask
{
	string class_name;

	ClassTask(CBlob@ blob_, const string&in class_name, const u8&in type, CBlob@ target = null)
	{
		super(blob_);
		solo = true;
		this.class_name = class_name;
		this.type = type;
		if (target !is null)
		{
			target_netid = target.getNetworkID();
			destination = target.getPosition();
		}
	}

	void Tick()
	{
		if (getInterval() % 30 != 0 && destination != Vec2f_zero) return;

		CBlob@ target = getBlobByNetworkID(target_netid);
		if (target is null || target.hasTag("dead"))
		{
			manager.SetNextTask(true);
			return;
		}

		destination = target.getPosition();

		if (blob.getDistanceTo(target) < target.getRadius())
		{
			ChangeClass();
			manager.SetNextTask(true);
			return;
		}
	}

	void ChangeClass()
	{
		CBlob@ newBlob = server_CreateBlobNoInit(class_name);
		if (newBlob is null) return;

		newBlob.server_setTeamNum(blob.getTeamNum());
		newBlob.setPosition(blob.getPosition());

		const float healthratio = blob.getHealth() / blob.getInitialHealth();
		newBlob.server_SetHealth(newBlob.getInitialHealth() * healthratio);

		blob.MoveInventoryTo(newBlob);

		const u32 netid = blob.exists("previous blob netid") ? blob.get_u32("previous blob netid") : blob.getNetworkID();
		newBlob.set_u32("previous blob netid", netid);

		newBlob.Init();

		blob.Tag("switch class");
		blob.server_Die();
	}
}

class ClassBuilderTask : ClassTask
{
	ClassBuilderTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_, "builder", Task::Builder, target);
		description = getTranslatedString("Builder");
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return ClassBuilderTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() == class_name) return false;

		return selected.getName() == "armory" || selected.getName() == "buildershop";
	}
}

class ClassKnightTask : ClassTask
{
	ClassKnightTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_, "knight", Task::Knight, target);
		description = getTranslatedString("Knight");
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return ClassKnightTask(blob_, target);
	}

	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() == class_name) return false;

		return selected.getName() == "armory" || selected.getName() == "knightshop";
	}
}

class ClassArcherTask : ClassTask
{
	ClassArcherTask(CBlob@ blob_, CBlob@ target = null)
	{
		super(blob_, "archer", Task::Archer, target);
		description = getTranslatedString("Archer");
	}

	BrainTask@ Copy(CBlob@ blob_, CBlob@ target = null)
	{
		return ClassArcherTask(blob_, target);
	}
	
	bool isTaskBlob(CBlob@ selected, CBlob@ worker)
	{
		if (worker.getName() == class_name) return false;

		return selected.getName() == "armory" || selected.getName() == "archershop";
	}
}
