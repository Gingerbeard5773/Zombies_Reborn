//Gingerbeard @ October 23, 2024

#include "Upgrades.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage * getDurabilityPercent();
}

f32 getDurabilityPercent()
{
	f32 percent = 1.0f;
	u32[]@ upgrades = getUpgrades();
	if (hasUpgrade(upgrades, Upgrade::IronChassis))  percent -= 0.25f;
	if (hasUpgrade(upgrades, Upgrade::SteelChassis)) percent -= 0.25f;
	return percent;
}
