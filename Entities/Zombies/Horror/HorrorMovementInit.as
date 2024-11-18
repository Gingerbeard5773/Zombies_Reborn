#include "UndeadMoveCommon.as"

UndeadMoveConsts@ consts = SetupConsts();

UndeadMoveConsts@ SetupConsts()
{
	UndeadMoveConsts consts;
	consts.walkSpeed = 1.45f;
	consts.walkFactor = 1.0f;

	consts.climbingFactor = 15;

	consts.jumpMaxVel = 3.0f;
	consts.jumpFactor = 1.05f;

	consts.stoppingForce = 0.80f;
	consts.stoppingForceAir = 0.60f;
	consts.stoppingFactor = 1.0f;
	return consts;
}

void onInit(CMovement@ this)
{
	UndeadMoveVars moveVars(consts);
	moveVars.jumpCount = 0;

	CBlob@ blob = this.getBlob();
	blob.set("moveVars", moveVars);
	blob.getShape().getVars().waterDragScale = 30.0f;
	blob.getShape().getConsts().collideWhenAttached = true;
}
