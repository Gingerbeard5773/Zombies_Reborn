// Gingerbeard @ October 2, 2024

funcdef void onAssignWorkerHandle(CBlob@, CBlob@);
funcdef void onUnassignWorkerHandle(CBlob@, CBlob@);

void addOnAssignWorker(CBlob@ this, onAssignWorkerHandle@ handle)     { this.set("onAssignWorker handle", @handle); }
void addOnUnassignWorker(CBlob@ this, onUnassignWorkerHandle@ handle) { this.set("onUnassignWorker handle", @handle); }

bool AssignWorkerButton(CBlob@ this, CBlob@ caller, Vec2f offset = Vec2f_zero)
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && !carried.hasTag("dead") && this.get_netid("assigned netid") <= 0)
	{
		CBitStream stream;
		stream.write_netid(carried.getNetworkID());
		caller.CreateGenericButton("$worker_migrant$", offset, this, this.getCommandID("server_attach_worker"), "Assign Worker", stream);
		return true;
	}
	return false;
}

bool UnassignWorkerButton(CBlob@ this, CBlob@ caller, Vec2f offset = Vec2f_zero)
{
	if (this.get_netid("assigned netid") > 0)
	{
		caller.CreateGenericButton("$worker_migrant$", offset, this, this.getCommandID("server_detach_worker"), "Unassign Worker");
		return true;
	}
	return false;
}

void Client_AttachWorker(CBlob@ this, CBlob@ worker)
{
	if (isClient()) return;
	CBitStream stream;
	stream.write_netid(worker.getNetworkID());
	this.SendCommand(this.getCommandID("client_attach_worker"), stream);
}

void Client_DetachWorker(CBlob@ this, CBlob@ worker)
{
	if (isClient()) return;
	CBitStream stream;
	stream.write_netid(worker.getNetworkID());
	this.SendCommand(this.getCommandID("client_detach_worker"), stream);
}

void AssignWorker(CBlob@ this, CBlob@ worker)
{
	worker.server_DetachFromAll();

	this.set_netid("assigned netid", worker.getNetworkID());
	worker.set_netid("assigned netid", this.getNetworkID());
	worker.set_Vec2f("brain_destination", this.getPosition());

	CSprite@ sprite = worker.getSprite();
	sprite.SetZ(-40);
	sprite.PlaySound("MigrantSayHello");
	
	onAssignWorkerHandle@ onAssign;
	if (this.get("onAssignWorker handle", @onAssign))
	{
		onAssign(this, worker);
	}
}

void UnassignWorker(CBlob@ this, CBlob@ worker)
{
	this.set_netid("assigned netid", 0);
	worker.set_netid("assigned netid", 0);

	CSprite@ sprite = worker.getSprite();
	sprite.SetZ(0);
	
	onUnassignWorkerHandle@ onUnassign;
	if (this.get("onUnassignWorker handle", @onUnassign))
	{
		onUnassign(this, worker);
	}
}

void SetWorkerStatic(CBlob@ worker, const bool&in isStatic = true)
{
	CShape@ shape = worker.getShape();
	shape.getVars().onground = true;
	shape.getConsts().collidable = !isStatic;
	shape.server_SetActive(!isStatic);
	worker.getMovement().doTickScripts = !isStatic;
}
