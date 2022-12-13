// Sedgwick brain

#define SERVER_ONLY

#include "BrainCommon.as";

void onInit(CBrain@ this)
{
	InitBrain(this);

	this.server_SetActive(true); // always running
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	
	SearchTarget(this);

	this.getCurrentScript().tickFrequency = 29;
	
	// logic for target
	CBlob@ target = this.getTarget();
	if (target !is null)
	{	
		this.getCurrentScript().tickFrequency = 1;

		f32 distance;
		const bool visibleTarget = isVisible(blob, target, distance);
		if (visibleTarget && distance < 80.0f) 
		{
			DefaultRetreatBlob(blob, target);
		}	

		if (distance < 250.0f)
		{
			blob.setAimPos(target.getPosition());
		}

		LoseTarget(this, target);
	}
	else
	{
		RandomTurn(blob);
	}

	FloatInWater(blob); 
} 
