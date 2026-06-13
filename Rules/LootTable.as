//Gingerbeard @ June 12, 2026

#include "MaterialCommon.as"
#include "MakeScroll.as"

//funcdef onMakeLootHandle(CBlob@);

shared class LootItem
{
	string item_name;
	int minimum, maximum, weight;
	LootItem(string item_name, int minimum, int maximum, int weight)
	{
		this.item_name = item_name;
		this.minimum = minimum;
		this.maximum = maximum;
		this.weight = weight;
	}
}

LootItem@ GetRandomLootItem(LootItem@[]@ items, Random@ seed)
{
	u32 weights_sum = 0;
	for (int i = 0; i < items.length; i++)
	{
		weights_sum += items[i].weight;
	}

	const u32 random_weight = seed.NextRanged(1 + weights_sum);
	u32 current_number = 0;

	for (int i = 0; i < items.length; i++)
	{
		LootItem@ item = items[i];
		if (random_weight <= current_number + item.weight)
		{
			return item;
		}

		current_number += item.weight;
	}

	return null;
}

void server_MakeLoot(LootItem@[]@ items, CBlob@ this)
{
	Random seed(this.getNetworkID() + Time());
	server_MakeLoot(items, this, seed);
}

void server_MakeLoot(LootItem@[]@ items, CBlob@ this, Random@ seed)
{
	if (!isServer()) return;
	
	LootItem@ item = GetRandomLootItem(items, seed);
	if (item is null) return;
	
	// Make a scroll if applicable - "scroll_carnage"
	string[]@ tokens = item.item_name.split("_");
	if (tokens.length > 1 && tokens[0] == "scroll")
	{
		CBlob@ blob = server_MakePredefinedScroll(this.getPosition(), tokens[1]);
		if (blob !is null)
		{
			this.server_PutInInventory(blob);
		}
		return;
	}
	
	// Otherwise just utilize material creation
	const u32 range = item.maximum - item.minimum + 1;
	const u32 extra = seed.NextRanged(range);
	const u32 amount = item.minimum + Maths::Min(extra, range - 1);

	Material::createFor(this, item.item_name, amount);
}
