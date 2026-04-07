//Skeleton Animations

#include "ParticleUndeadGib.as"

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!this.isAnimationEnded() && this.isAnimation("attack")) return;

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	if (blob.isOnLadder() && (up || down))
	{
		if (!this.isAnimation("jump"))
			 this.SetAnimation("jump");
	}
	else if (left || right)
	{
		if (!this.isAnimation("walk"))
			 this.SetAnimation("walk");
	}
	else
	{
		if (!this.isAnimation("default"))
			 this.SetAnimation("default");
	}
}

void onGib(CSprite@ this)
{
	UndeadGibs(this, "SkeletonGibs.png");
}
