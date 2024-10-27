// Gingerbeard @ October 2, 2024

#include "Zombie_Translation.as"

funcdef void onAssignWorkerHandle(CBlob@, CBlob@);
funcdef void onUnassignWorkerHandle(CBlob@, CBlob@);

void addOnAssignWorker(CBlob@ this, onAssignWorkerHandle@ handle)     { this.set("onAssignWorker handle", @handle); }
void addOnUnassignWorker(CBlob@ this, onUnassignWorkerHandle@ handle) { this.set("onUnassignWorker handle", @handle); }

bool AssignWorkerButton(CBlob@ this, CBlob@ caller, Vec2f offset = Vec2f_zero)
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && !carried.hasTag("dead") && hasAvailableWorkerSlots(this))
	{
		CBitStream stream;
		stream.write_netid(carried.getNetworkID());
		caller.CreateGenericButton("$worker_migrant$", offset, this, this.getCommandID("server_attach_worker"), Translate::AssignWorker, stream);
		return true;
	}
	return false;
}

bool UnassignWorkerButton(CBlob@ this, CBlob@ caller, Vec2f offset = Vec2f_zero)
{
	if (getWorkers(this).length > 0)
	{
		caller.CreateGenericButton("$worker_migrant$", offset, this, this.getCommandID("server_detach_worker"), Translate::UnassignWorker);
		return true;
	}
	return false;
}

void RequiresWorkerButton(CBlob@ this, CBlob@ caller, Vec2f offset = Vec2f_zero)
{
	CButton@ button = caller.CreateGenericButton("$worker_migrant$", offset, this, 0, Translate::WorkerRequired);
	if (button !is null)
	{
		button.SetEnabled(false);
	}
}

void Client_AttachWorker(CBlob@ this, const u16&in worker_netid)
{
	if (isClient()) return;
	CBitStream stream;
	stream.write_netid(worker_netid);
	this.SendCommand(this.getCommandID("client_attach_worker"), stream);
}

void Client_DetachWorker(CBlob@ this, const u16&in worker_netid)
{
	if (isClient()) return;
	CBitStream stream;
	stream.write_netid(worker_netid);
	this.SendCommand(this.getCommandID("client_detach_worker"), stream);
}

void AssignWorker(CBlob@ this, const u16&in worker_netid)
{
	getWorkers(this).push_back(worker_netid);
	
	CBlob@ worker = getBlobByNetworkID(worker_netid);
	if (worker !is null)
	{
		worker.server_DetachFromAll();
		worker.set_netid("assigned netid", this.getNetworkID());
		worker.set_Vec2f("brain_destination", this.getPosition());

		worker.getSprite().PlaySound("MigrantSayHello");
		
		onAssignWorkerHandle@ onAssign;
		if (this.get("onAssignWorker handle", @onAssign))
		{
			onAssign(this, worker);
		}
	}
}

void UnassignWorker(CBlob@ this, const u16&in worker_netid)
{
	u16[]@ workers = getWorkers(this);
	const int index = workers.find(worker_netid);
	if (index != -1)
	{
		workers.erase(index);
	}
	
	CBlob@ worker = getBlobByNetworkID(worker_netid);
	if (worker !is null)
	{
		worker.set_netid("assigned netid", 0);

		onUnassignWorkerHandle@ onUnassign;
		if (this.get("onUnassignWorker handle", @onUnassign))
		{
			onUnassign(this, worker);
		}
	}
}

u16[]@ getWorkers(CBlob@ this)
{
	u16[]@ netids;
	this.get("assigned netids", @netids);
	return netids;
}

bool hasAvailableWorkerSlots(CBlob@ this)
{
	return getWorkers(this).length < this.get_u8("maximum_worker_count");
}

void SetStandardWorkerPosition(CBlob@ this, CBlob@ worker)
{
	AttachmentPoint@[] aps;
	if (!this.getAttachmentPoints(@aps)) return;

	for (u8 i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ ap = aps[i];
		CBlob@ occupied = ap.getOccupied();
		if (ap.name != "WORKER" || (occupied !is null && occupied !is worker)) continue;

		Random rand(this.getNetworkID() + worker.getNetworkID());
		const f32 width = int(rand.NextRanged(this.getWidth()*0.5f)) - (this.getWidth() * 0.25f);
		Vec2f offset = Vec2f(width, (this.getHeight() - worker.getHeight()) * 0.5f);

		ap.offsetZ = 25.0f;
		ap.offset = offset;

		worker.SetFacingLeft(rand.NextRanged(2) == 0);
		this.server_AttachTo(worker, ap);

		break;
	}
}
