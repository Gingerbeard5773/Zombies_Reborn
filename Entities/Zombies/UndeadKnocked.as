//Gingerbeard @ September 30, 2024

#include "Hitters.as"
#include "Zombie_TechnologyCommon.as"
#include "UndeadKnockedCommon.as"

const u8 STUN_TICKS = 6 * 30;
const u8 STUN_TICKS_TECH = 12 * 30;

void onInit(CBlob@ this)
{
	this.set_u32("stun_time", 0);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::water_stun || customData == Hitters::water_stun_force)
	{
		const u8 ticks_to_stun = hasTech(Tech::HolyWater) ? STUN_TICKS_TECH : STUN_TICKS;
		setUndeadKnocked(this, ticks_to_stun);
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
	
	this.getCurrentScript().tickFrequency = 15;

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
