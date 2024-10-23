
bool canEat(CBlob@ blob)
{
	return blob.exists("eat sound");
}

bool canHealOnCollide(CBlob@ food)
{
	const string name = food.getName();
	return name == "heart" || name == "flowers";
}

// returns the healing amount of a certain food (in quarter hearts) or 0 for non-food
u8 getHealingAmount(CBlob@ food)
{
	const string name = food.getName();
	
	if (!canEat(food) || name == "grain")
	{
		return 0;
	}
	
	if (name == "heart" || name == "egg" || name == "flowers")
	{
		return 4;
	}
	
	if (name == "fishy")
	{
		return 6;
	}

	if (name == "food")
	{
		return 26;
	}
	
	return food.getHealth();
}

void Heal(CBlob@ this, CBlob@ food)
{
	if (!isServer()) return;
	
	if (!this.hasTag("player") || this.hasTag("undead") || food.hasTag("healed")) return;

	const f32 oldHealth = this.getHealth();
	const f32 initialHealth = this.getInitialHealth();
	if (oldHealth >= initialHealth) return;

	const u8 heal_amount = getHealingAmount(food);
	if (heal_amount <= 0) return;

	if (heal_amount == 255)
	{
		this.server_SetHealth(initialHealth);
	}
	else
	{
		const f32 heal = f32(heal_amount) * 0.125f;
		const f32 healthRatio = heal / (1.5f / initialHealth); //ratio the health between classes
		this.server_SetHealth(oldHealth + healthRatio);
	}

	food.Tag("healed");
	food.SendCommand(food.getCommandID("heal command client"));
	food.server_Die();
}
