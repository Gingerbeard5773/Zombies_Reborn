//Give a player a temporary parachute

void onInit(CBlob@ this)
{
	if (isClient())
	{
		if (this.hasTag("parachute landed")) return; //networking reasons
		
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ chute = sprite.addSpriteLayer("parachute", "Crate.png", 32, 32);
		if (chute !is null)
		{
			Animation@ anim = chute.addAnimation("default", 0, true);
			anim.AddFrame(4);
			chute.SetOffset(Vec2f(0.0f, - 17.0f));
		}
		
		sprite.PlaySound("GetInVehicle");
	}
}

void onTick(CBlob@ this)
{
	//slow down the player's fall speed
	Vec2f vel = this.getVelocity();
	this.setVelocity(Vec2f(vel.x, vel.y * 0.8f));
	
	const bool canremove = (this.isOnGround() || this.isInWater() || this.isAttached() || this.isOnLadder());
	if (canremove)
	{
		HideParachute(this);
	}
}

void onDie(CBlob@ this)
{
	HideParachute(this);
}

void HideParachute(CBlob@ this)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ chute = sprite.getSpriteLayer("parachute");
		if (chute !is null && chute.isVisible())
		{
			ParticlesFromSprite(chute);
			sprite.PlaySound("join");
			sprite.RemoveSpriteLayer("parachute");
		}
	}
	
	this.Tag("parachute landed");
	this.RemoveScript(getCurrentScriptName());
}
