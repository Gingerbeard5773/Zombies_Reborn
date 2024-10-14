#include "UndeadMoveCommon.as"

UndeadMoveConsts@ consts = SetupConsts();

UndeadMoveConsts@ SetupConsts()
{
	UndeadMoveConsts consts;
	consts.flySpeed = 1.4f;
	consts.flyFactor = 1.0f;

	consts.stoppingForce = 0.80f;
	consts.stoppingForceAir = 0.60f;
	consts.stoppingFactor = 1.0f;
	
	return consts;
}

void onInit(CMovement@ this)
{
	UndeadMoveVars moveVars(consts);

	CBlob@ blob = this.getBlob();
	blob.set("moveVars", moveVars);
	blob.getShape().getVars().waterDragScale = 30.0f;
	blob.getShape().getConsts().collideWhenAttached = true;
}
