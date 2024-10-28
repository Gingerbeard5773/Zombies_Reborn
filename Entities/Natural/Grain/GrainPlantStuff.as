#include "PlantGrowthCommon.as";
#include "MakeSeed.as";
#include "Zombie_TechnologyCommon.as";

void onInit(CBlob@ this)
{
	this.set_u8(growth_time, 90);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onDie(CBlob@ this)
{
	if (!isServer() || !this.hasTag("has grain")) return;

	u8 quantity = 1;
	if (XORRandom(5) == 0 && hasTech(Tech::PlentifulWheat))
	{
		quantity += 1;
	}
	
	server_MakeSeed(this.getPosition(), "grain_plant");

	for (u8 i = 0; i < quantity; i++)
	{
		CBlob@ grain = server_CreateBlob("grain", this.getTeamNum(), this.getPosition() + Vec2f(0, -12));
		if (grain !is null)
		{
			grain.setVelocity(Vec2f(XORRandom(5) - 2.5f, XORRandom(5) - 2.5f));
		}
	}
}
