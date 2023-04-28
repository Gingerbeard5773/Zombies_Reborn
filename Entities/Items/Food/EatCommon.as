const string heal_id = "heal command";

bool canEat(CBlob@ blob)
{
	return blob.exists("eat sound");
}

// returns the healing amount of a certain food (in quarter hearts) or 0 for non-food
u8 getHealingAmount(CBlob@ food)
{
	const string food_name = food.getName(); //  HACK
	
	if (!canEat(food) || food_name == "grain")
	{
		return 0;
	}
	
	if (food_name == "heart" || food_name == "egg" || food_name == "flowers" || food_name == "fishy")
	{
		return 4;
	}
	
	if (food_name == "food")
	{
		return 16;
	}
	
	return food.getHealth();
}

void Heal(CBlob@ this, CBlob@ food)
{
	const bool exists = getBlobByNetworkID(food.getNetworkID()) !is null;
	if (isServer() && this.hasTag("player") && !this.hasTag("undead") && this.getHealth() < this.getInitialHealth() && !food.hasTag("healed") && exists)
	{
		const u8 heal_amount = getHealingAmount(food);
		if (heal_amount > 0)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID());
			params.write_u8(heal_amount);
			food.SendCommand(food.getCommandID(heal_id), params);

			food.Tag("healed");
		}
	}
}
