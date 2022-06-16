// Zombie Fortress parachute supplies

#include "MakeCrate.as";

const string[] vehicles = { "catapult", "ballista", "mounted_bow", "bomber" };

const string[] food = { "food", "steak", "grain" };

const string[] resources = { "mat_wood", "mat_stone" };

const string[] bombs = { "mat_bombs" };

const string[] fire = { "mat_firearrows" };

const string[] water = { "mat_waterbombs", "mat_waterarrows" };

const string[] bombarrows = { "mat_bombarrows" };

const string[] keg = { "keg" };

void spawnSupplies()
{
	const u8 supplyCrateNum = XORRandom(8);
	switch(supplyCrateNum)
	{
		case 0:
		{
			const u8 vehicleNum = XORRandom(vehicles.length);
			server_MakeCrateOnParachute(vehicles[vehicleNum], "Vehicle", vehicleNum+4, 0, getDropPos());
			break;
		}
		case 1:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Food", 26, 0, getDropPos());
			addToInventory(crate, food, 6);
			break;
		}
		case 2:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Bombs", 12, 0, getDropPos());
			addToInventory(crate, bombs, 5);
			break;
		}
		case 3:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Water Ammo", 15, 0, getDropPos());
			addToInventory(crate, water, 4);
			break;
		}
		case 4:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Fire Arrows", 14, 0, getDropPos());
			addToInventory(crate, fire, 5);
			break;
		}
		case 5:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Bomb Arrows", 17, 0, getDropPos());
			addToInventory(crate, bombarrows, 3);
			break;
		}
		case 6:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Resources", 29, 0, getDropPos());
			addToInventory(crate, resources, 4);
			break;
		}
		case 7:
		{
			CBlob@ crate = server_MakeCrateOnParachute("", "Keg", 13, 0, getDropPos());
			addToInventory(crate, keg, 1);
			break;
		}
	}
}

void addToInventory(CBlob@ this, const string[]&in blobnames, const u8&in amount)
{
	for (u8 i = 0; i < amount; i++)
	{
		CBlob@ b = server_CreateBlob(blobnames[XORRandom(blobnames.length)], -1, this.getPosition());
		this.server_PutInInventory(b);
	}
}

Vec2f getDropPos()
{
	const Vec2f dim = getMap().getMapDimensions();
	return Vec2f(XORRandom(dim.x), 0);
}
