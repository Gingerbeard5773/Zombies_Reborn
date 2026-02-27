#include "Knocked.as"

void onInit(CBlob@ this)
{	
	if (this.isMyPlayer())
	{
		getDriver().SetShader("drunk", true);
	}
}

void onTick(CBlob@ this)
{
	const u16 level = this.get_u16("drunk");
	
	Random rand(this.getNetworkID() + getGameTime());
	if (rand.NextRanged(1000) == 0)
	{
		this.set_u16("drunk", Maths::Max(this.get_u16("drunk") - 1, 0));
	}

	if (getKnocked(this) < 10 && rand.NextRanged(8000 / (1 + level * 1.5f)) == 0)
	{
		const u8 knock = 5 + rand.NextRanged(3) * level;
	
		SetKnocked(this, knock);
		//this.getSprite().PlaySound("drunk_fx" + XORRandom(5), 0.8f, this.getSexNum() == 0 ? 1.0f : 2.0f);
	}
	
	if (this.isMyPlayer())
	{
		Driver@ driver = getDriver();
		driver.SetShaderFloat("drunk", "time", getGameTime() / 30.0f);
		driver.SetShaderFloat("drunk", "wobble_strength", level * 0.0002f);
		driver.SetShaderFloat("drunk", "aberration_strength", level * 0.0001f);
	}
	
	if (level == 0 || this.hasTag("dead"))
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

void onDie(CBlob@ this)
{
	this.set_u16("drunk", 0);

	if (this.isMyPlayer())
	{
		getDriver().SetShader("drunk", false);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 modifier = Maths::Max(0.3f, Maths::Min(1, Maths::Pow(0.80f, this.get_u16("drunk"))));
	return damage * modifier;
}
