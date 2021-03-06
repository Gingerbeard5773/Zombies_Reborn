#include "UndeadMoveCommon.as"

void onInit(CMovement@ this)
{
    UndeadMoveVars moveVars;

    //flying vars
    moveVars.flySpeed = 1.4f;
    moveVars.flyFactor = 1.0f;
    
    //stopping forces
    moveVars.stoppingForce = 0.80f; //function of mass
    moveVars.stoppingForceAir = 0.60f; //function of mass
    moveVars.stoppingFactor = 1.0f;

	//
    this.getBlob().set("moveVars", moveVars);
    this.getBlob().getShape().getVars().waterDragScale = 30.0f;
	this.getBlob().getShape().getConsts().collideWhenAttached = true;
}
