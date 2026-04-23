// Wraith extinguish from water

#include "Hitters.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("client_extinguish");

	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (this.isInWater())
	{
		server_Extinguish(this, false);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isWaterHitter(customData) && this.hasTag("exploding"))
	{
		CPlayer@ damagePlayer = hitterBlob.getDamageOwnerPlayer();
		if (damagePlayer !is null && damagePlayer.isMyPlayer())
		{
			Achievement::client_Unlock(Achievement::NotTodayBuddy);
		}

		server_Extinguish(this, true);
	}

	return damage;
}

void server_Extinguish(CBlob@ this, const bool&in stun = true)
{
	if (!isServer()) return;

	if (!this.hasTag("exploding")) return;

	this.set_bool("exploding", false);

	this.server_SetTimeToDie(-1);

	if (stun)
	{
		this.getBrain().SetTarget(null);
		this.set_u8("brain_delay", 250); //do a fake stun

		this.setKeyPressed(key_left, false);
		this.setKeyPressed(key_right, false);
		this.setKeyPressed(key_up, false);
		this.setKeyPressed(key_down, false);
	}

	//why the fuck does kag need light on server to work. fuckers
	this.SetLight(false);

	CBitStream params;
	params.write_bool(stun);
	this.SendCommand(this.getCommandID("client_extinguish"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_extinguish") && isClient())
	{
		bool stun;
		if (!params.saferead_bool(stun)) { error("Failed to read stun! [WraithExtinguishFromWater]"); return; }

		this.set_bool("exploding", false);

		this.SetLight(false);
		this.getSprite().PlaySound("Steam.ogg");

		if (stun)
		{
			this.set_u32("stun_time", getGameTime() + 250);
		}

		//steam particles
		for (u8 i = 0; i < 5; i++)
		{
			Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
			ParticleAnimated("MediumSteam", this.getPosition(), vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
		}
	}
}
