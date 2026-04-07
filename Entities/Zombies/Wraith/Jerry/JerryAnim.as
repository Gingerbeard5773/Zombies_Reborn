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

	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 magnitude = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();

	UndeadGib("JerryGibs.png", pos, vel, magnitude, 0, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 1, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 2, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 3, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 4, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 5, team);
	UndeadGib("JerryGibs.png", pos, vel, magnitude, 6, team);
}
