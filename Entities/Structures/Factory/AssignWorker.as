// Gingerbeard @ October 2, 2024
//assign migrants to something

#include "AssignWorkerCommon.as";
#include "MigrantCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_attach_worker");
	this.addCommandID("client_attach_worker");
	this.addCommandID("server_detach_worker");
	this.addCommandID("client_detach_worker");
	
	this.getCurrentScript().tickFrequency = 90;
	
	if (!this.exists("maximum_worker_count"))
		this.set_u8("maximum_worker_count", 1);
	
	u16[] netids;
	this.set("assigned netids", netids);
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (this.hasTag("auto_assign_worker") && hasAvailableWorkerSlots(this))
	{
		server_AutoAssignWorker(this);
	}
}

void server_AutoAssignWorker(CBlob@ this)
{
	CBlob@[] overlapping;
	if (!this.getOverlapping(overlapping)) return;

	for (u16 i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		if (!b.hasTag("migrant") || b.hasTag("dead")) continue;

		if (b.isAttached() || b.get_u8("strategy") == Strategy::runaway || b.get_netid("assigned netid") > 0) continue;
		
		AssignWorker(this, b.getNetworkID());
		Client_AttachWorker(this, b.getNetworkID());
		break;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_attach_worker") && isServer())
	{
		if (!hasAvailableWorkerSlots(this)) return;

		u16 worker_netid;
		if (!params.saferead_netid(worker_netid))  { error("Failed to assign worker! [0] : "+this.getNetworkID()); return; }

		AssignWorker(this, worker_netid);
		Client_AttachWorker(this, worker_netid);
	}
	else if (cmd == this.getCommandID("client_attach_worker") && isClient())
	{
		u16 worker_netid;
		if (!params.saferead_netid(worker_netid)) { error("Failed to assign worker! [1] : "+this.getNetworkID()); return; }

		AssignWorker(this, worker_netid);
	}
	else if (cmd == this.getCommandID("server_detach_worker") && isServer())
	{
		u16[]@ netids = getWorkers(this);
		if (netids.length <= 0) return;
		
		const u16 worker_netid = netids[0];

		CBlob@ worker = getBlobByNetworkID(worker_netid);
		if (worker !is null)
			worker.IgnoreCollisionWhileOverlapped(this); //dont auto-assign the worker

		UnassignWorker(this, worker_netid);
		Client_DetachWorker(this, worker_netid);
	}
	else if (cmd == this.getCommandID("client_detach_worker") && isClient())
	{
		u16 worker_netid;
		if (!params.saferead_netid(worker_netid)) { error("Failed to unassign worker! [0] : "+this.getNetworkID()); return; }

		UnassignWorker(this, worker_netid);
	}
}

void onDie(CBlob@ this)
{
	u16[] netids = getWorkers(this);
	for (u8 i = 0; i < netids.length; i++)
	{
		UnassignWorker(this, netids[i]);
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	u16[] netids;
	this.get("assigned netids", netids);
	
	stream.write_u8(netids.length);
	for (u8 i = 0; i < netids.length; i++)
	{
		stream.write_netid(netids[i]);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	if (!UnserializeAssigned(this, stream))
	{
		error("Failed to access assigned workers! : "+this.getName()+" : "+this.getNetworkID());
		return false;
	}
	return true;
}

bool UnserializeAssigned(CBlob@ this, CBitStream@ stream)
{
	u8 netids_length;
	if (!stream.saferead_u8(netids_length)) return false;
	
	u16[] netids;
	for (u8 i = 0; i < netids_length; i++)
	{
		u16 netid;
		if (!stream.saferead_netid(netid)) return false;
		netids.push_back(netid);
	}
	
	this.set("assigned netids", netids);

	return true;
}
