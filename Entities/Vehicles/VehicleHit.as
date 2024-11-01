//Gingerbeard @ October 23, 2024

#include "Zombie_TechnologyCommon.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage * getDurabilityPercent();
}

f32 getDurabilityPercent()
{
	f32 percent = 1.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::IronChassis))  percent -= 0.25f;
	if (hasTech(TechTree, Tech::SteelChassis)) percent -= 0.35f;
	return percent;
}
