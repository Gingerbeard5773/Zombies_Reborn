//Gingerbeard @ October 23, 2024

#include "Zombie_TechnologyCommon.as";
#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	Technology@[]@ TechTree = getTechTree();
	if (customData == Hitters::fire || customData == Hitters::burn)
	{
		if (hasTech(TechTree, Tech::ThermalHull))
		{
			return 0.0f;
		}
	}

	return damage * getDurabilityPercent(TechTree);
}

f32 getDurabilityPercent(Technology@[]@ TechTree)
{
	f32 percent = 1.0f;
	if (hasTech(TechTree, Tech::IronChassis))  percent -= 0.25f;
	if (hasTech(TechTree, Tech::SteelChassis)) percent -= 0.35f;
	return percent;
}
