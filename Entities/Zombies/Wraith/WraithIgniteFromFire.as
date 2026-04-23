// Wraith ignites from fire hitters

#include "Hitters.as"
#include "WraithCommon.as"
#include "Zombie_AchievementsCommon.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::fire && !this.hasTag("exploding"))
	{
		if (hitterBlob.getName() == "arrow" && this.getHealth() <= 0.0f)
		{
			CPlayer@ damagePlayer = hitterBlob.getDamageOwnerPlayer();
			if (damagePlayer !is null && damagePlayer.isMyPlayer())
			{
				Achievement::client_Unlock(Achievement::SpontaneousCombustion);
			}
		}

		server_SetEnraged(this);
	}

	return damage;
}
