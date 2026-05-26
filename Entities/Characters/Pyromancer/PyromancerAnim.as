// Pyromancer animations

#include "RunnerAnimCommon.as"
#include "RunnerCommon.as"
#include "RunnerTextures.as"

void onInit(CSprite@ this)
{
	addRunnerTextures(this, "pyromancer", "Pyromancer");
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
		}

		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 2.0f)
		{
			this.SetFrameIndex(1);
		}
		else
		{
			this.SetFrameIndex(2);
		}

		return;
	}

	// animations
	const bool firing = blob.isKeyPressed(key_action1);
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	const bool inair = false && (!blob.isOnGround() && !blob.isOnLadder());

	bool crouch = false;

	bool knocked = blob.get_u8("wizard_knocked") > 0;
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	// get the angle of aiming with mouse
	Vec2f vec = aimpos - pos;
	f32 angle = vec.Angle();

	if (knocked)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("default");
	}
	else if (firing)
	{
		if (inair)
		{
			this.SetAnimation("jump");
		}
		else if ((left || right) || (blob.isOnLadder() && (up || down)))
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fire");
		}
	}
	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars)) return;

		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;
			bool inwater = blob.isInWater();

			if (vy < -1.5f * (inwater ? 0.7f : 1))
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5f * (inwater ? 0.7f : 1))
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if ((left || right) || (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		if (down && this.isAnimationEnded())
			crouch = true;

		int direction;

		if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
		        (angle > 150 && angle < 210))
		{
			direction = 0;
		}
		else if (aimpos.y < pos.y)
		{
			direction = -1;
		}
		else
		{
			direction = 1;
		}

		defaultIdleAnim(this, blob, direction);
	}

	//set the head anim
	if (knocked || crouch)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) return;

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()),2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team);
	makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team);
	makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}
