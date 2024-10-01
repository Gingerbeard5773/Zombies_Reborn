//Gingerbeard @ September 30, 2024

#include "Hitters.as";

const u8 STUN_TICKS = 6 * 30;

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::water_stun || customData == Hitters::water_stun_force)
	{
		if (isServer())
		{
			this.set_u8("brain_delay", STUN_TICKS);

			this.setKeyPressed(key_left, false);
			this.setKeyPressed(key_right, false);
			this.setKeyPressed(key_up, false);
			this.setKeyPressed(key_down, false);

			this.server_DetachAll(); //save players from gregs
		}

		this.set_u32("stun_time", getGameTime() + STUN_TICKS);
	}

	return damage;
}

///SPRITE

void onInit(CSprite@ this)
{
	if (v_fastrender) //no dazzle rendering for shit gpu
	{
		this.getCurrentScript().tickFrequency = 0;
		return;
	}

	CSpriteLayer@ stars = this.addSpriteLayer("dazzle stars", "Dazzle.png" , 16, 9, 0, 0);
	if (stars !is null)
	{
		Animation@ anim = stars.addAnimation("default", 3, true);

		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);

		stars.SetVisible(false);
		stars.SetRelativeZ(2.0f);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	CSpriteLayer@ stars = this.getSpriteLayer("dazzle stars");
	if (blob.get_u32("stun_time") > getGameTime() && !blob.hasTag("dead"))
	{ 
		stars.SetVisible(true);

		Vec2f off = Vec2f(0, -this.getFrameHeight() * 0.1f);
		off += this.getOffset();
		off += Vec2f(Maths::Round(Maths::Sin(getGameTime() * 0.2f) * 3 + 1), Maths::Round(-3 - Maths::Abs(Maths::Cos(getGameTime() * 0.15f) * 3)));
		stars.SetOffset(off);
	}
	else
	{
		stars.SetVisible(false);
	}
}
