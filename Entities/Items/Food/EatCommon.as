
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
	
	if (food_name == "fishy")
	{
		return 6;
	}

	if (food_name == "food")
	{
		return 26;
	}
	
	return food.getHealth();
}

void Heal(CBlob@ this, CBlob@ food)
{
	if (this.hasTag("undead")) return; //dont let the undead eat!

	bool exists = getBlobByNetworkID(food.getNetworkID()) !is null;
	const f32 initialHealth = this.getInitialHealth();
	if (isServer() && this.hasTag("player") && this.getHealth() < initialHealth && !food.hasTag("healed") && exists)
	{
		u8 heal_amount = getHealingAmount(food);
		if (heal_amount <= 0) return;

		if (heal_amount == 255)
		{
			this.add_f32("heal amount", initialHealth - this.getHealth());
			this.server_SetHealth(initialHealth);
		}
		else
		{
			const f32 oldHealth = this.getHealth();
			const f32 heal = f32(heal_amount) * 0.125f;
			const f32 healthRatio = heal / (1.5f / initialHealth); //ratio the health between classes
			this.server_SetHealth(oldHealth + healthRatio);
			this.add_f32("heal amount", this.getHealth() - oldHealth);
		}

		//give coins for healing teammate
		if (food.exists("healer"))
		{
			CPlayer@ player = this.getPlayer();
			u16 healerID = food.get_u16("healer");
			CPlayer@ healer = getPlayerByNetworkId(healerID);
			if (player !is null && healer !is null)
			{
				bool healerHealed = healer is player;
				bool sameTeam = healer.getTeamNum() == player.getTeamNum();
				if (!healerHealed && sameTeam)
				{
					int coins = 10;
					healer.server_setCoins(healer.getCoins() + coins);
				}
			}
		}

		this.Sync("heal amount", true);

		food.Tag("healed");

		food.SendCommand(food.getCommandID("heal command client")); // for sound

		food.server_Die();
	}
}