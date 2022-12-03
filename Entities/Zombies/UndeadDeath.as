const u32 REVIVE_SECS = 20;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.set_u32("death time", getGameTime());

		// add pickup attachment so we can pickup body
		CAttachment@ a = this.getAttachments();
		if (a !is null)
		{
			AttachmentPoint@ ap = a.AddAttachmentPoint("PICKUP", false);
		}

		this.getCurrentScript().tickFrequency = 30;

		CShape@ shape = this.getShape();
		// new physics vars so bodies don't slide
		shape.setFriction(0.75f);
		shape.setElasticity(0.2f);

		// disable tags
		shape.getVars().isladder = false;
		shape.getVars().onladder = false;
		shape.checkCollisionsAgain = true;
		shape.SetGravityScale(1.0f);

		// fall out of attachments/seats // drop all held things
		this.server_DetachAll();
	}
	else
	{
		this.set_u32("death time", getGameTime());
	}
	
	return damage;
}

void onTick(CBlob@ this)
{
	// revive our zombie
	if (this.get_u32("death time") + REVIVE_SECS * getTicksASecond() < getGameTime())
	{
		if (isClient())
		{
			this.getSprite().SetAnimation("revive");
			Sound::Play(this.getName() == "zombieknight" ? "ZombieKnightGrowl" : "ZombieSpawn", this.getPosition());
		}
		
		this.Untag("dead");
		this.set_u32("death time", 0);
		this.server_SetHealth(this.getInitialHealth());
		this.server_DetachAll();
		this.getCurrentScript().tickFrequency = 0;
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}
