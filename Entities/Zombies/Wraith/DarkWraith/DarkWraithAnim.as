//Wraith Animations

#include "ParticleUndeadGib.as"

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("exploding"))
	{
		if (!this.isAnimation("attack"))
			this.SetAnimation("attack");
	}
	else if (!blob.isOnGround() && !blob.isOnLadder()) 
	{
		if (!this.isAnimation("fly"))
			this.SetAnimation("fly");
	}
	else if (!this.isAnimation("walk"))
			 this.SetAnimation("walk");
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) return;

	CBlob@ blob = this.getBlob();
	if (blob.hasTag("exploding")) return;

	UndeadGibs(this, "DarkWraithGibs.png");
}
