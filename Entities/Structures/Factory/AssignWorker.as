// Gingerbeard @ October 2, 2024
//assign a migrant to something

#include "AssignWorkerCommon.as";
#include "MigrantCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_attach_worker");
	this.addCommandID("client_attach_worker");
	this.addCommandID("server_detach_worker");
	this.addCommandID("client_detach_worker");
	
	this.getCurrentScript().tickFrequency = 90;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (this.hasTag("auto_assign_worker") && this.get_netid("assigned netid") <= 0)
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
		
		AssignWorker(this, b);
		Client_AttachWorker(this, b);
		break;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_attach_worker") && isServer())
	{
		CBlob@ worker = getBlobByNetworkID(params.read_netid());
		if (worker is null) return;
		
		if (this.get_netid("assigned netid") > 0) return;

		AssignWorker(this, worker);
		Client_AttachWorker(this, worker);
	}
	else if (cmd == this.getCommandID("client_attach_worker") && isClient())
	{
		CBlob@ worker = getBlobByNetworkID(params.read_netid());
		if (worker is null) return;

		AssignWorker(this, worker);
	}
	else if (cmd == this.getCommandID("server_detach_worker") && isServer())
	{
		CBlob@ worker = getBlobByNetworkID(this.get_netid("assigned netid"));
		if (worker is null) return;
		
		worker.IgnoreCollisionWhileOverlapped(this); //dont auto-assign the worker

		UnassignWorker(this, worker);
		Client_DetachWorker(this, worker);
	}
	else if (cmd == this.getCommandID("client_detach_worker") && isClient())
	{
		CBlob@ worker = getBlobByNetworkID(params.read_netid());
		if (worker is null) return;

		UnassignWorker(this, worker);
	}
}

void onDie(CBlob@ this)
{
	CBlob@ worker = getBlobByNetworkID(this.get_netid("assigned netid"));
	if (worker !is null)
	{
		UnassignWorker(this, worker);
	}
}
