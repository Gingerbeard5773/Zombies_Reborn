// Sedgwick animations

const u8 orbcount = 6;

void onInit(CSprite@ this)
{
	Vec2f orbOffset = Vec2f(0, 24);
	for (u16 i = 0; i < orbcount; ++i)
	{
		CSpriteLayer@ orb = this.addSpriteLayer("orb"+i, "MagicOrb.png", 8, 8, 1, 0);
		if (orb !is null)
		{
			Animation@ anim = orb.addAnimation("default", 6, true);
			int[] frames = { 0, 1, 2, 3, 2, 1 };
			anim.AddFrames(frames);
			anim.SetFrameIndex(i);
			
			orbOffset.RotateBy(60.0f);
			orb.SetOffset(orbOffset);
			orb.SetRelativeZ(1000);
			orb.SetVisible(false);
		}
	}
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();    
    
	// get facing
	const bool inspell = blob.getShape().isStatic();
   	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	if (blob.isKeyPressed(key_action1))
	{
		this.SetAnimation("fire");
	}
	else if (inair || inspell)
	{
		this.SetAnimation("fall");
		this.animation.timer = 0;

		if (blob.getVelocity().y < -1.5 || up || inspell)
		{
			this.animation.frame = 0;
		}
		else
		{
			this.animation.frame = 1;
		}
	}
	else if (left || right || (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		this.SetAnimation("default");
	}
	
	for (u8 i = 0; i < orbcount; i++)
	{
		CSpriteLayer@ orb = this.getSpriteLayer("orb"+i);
		if (orb is null) break;
		
		orb.RotateBy(1, orb.getOffset());
		Vec2f rotation = orb.getOffset();
		rotation.RotateBy(4.0f);
		orb.SetOffset(rotation);
		orb.SetFacingLeft(false);
	}
}

/*void onGib(CSprite@ this)
{
    if (g_kidssafe) return;

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
    CParticle@ Body     = makeGibParticle( "Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team);
    CParticle@ Arm1     = makeGibParticle( "Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team);
    CParticle@ Arm2     = makeGibParticle( "Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team);
    CParticle@ Shield   = makeGibParticle( "Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team);
    CParticle@ Sword    = makeGibParticle( "Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}*/
