const u32 REVIVE_SECS = 20;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30;
	this.getCurrentScript().tickIfTag = "dead";
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.set_u32("death time", getGameTime());

		if (isClient())
		{
			const string name = this.getName();
			string sound = "ZombieDie";
			if (name == "zombieknight") sound = "ZombieKnightDie";
			else if (name == "horror")  sound = "HorrorDie";

			this.getSprite().PlaySound(sound);
		}

		CShape@ shape = this.getShape();
		shape.setFriction(0.75f);
		shape.setElasticity(0.2f);
		shape.getVars().isladder = false;
		shape.getVars().onladder = false;
		shape.checkCollisionsAgain = true;
		shape.SetGravityScale(1.0f);

		this.server_DetachAll();
	}
	else if (this.hasTag("dead"))
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

			const string name = this.getName();
			string sound = "ZombieSpawn";
			if (name == "zombieknight") sound = "ZombieKnightGrowl";

			if (name != "horror")
			{
				Sound::Play(sound, this.getPosition());
			}
		}

		this.Untag("dead");
		this.set_u32("death time", 0);
		this.server_SetHealth(this.getInitialHealth());
		this.server_DetachAll();
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}
