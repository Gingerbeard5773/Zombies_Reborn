// Gingerbeard @ July 29th, 2025

const string fuel_prop = "fuel_level";
const string[] fuel_names = {"mat_wood", "mat_coal"};
const string[] fuel_icons = {"mat_wood", "mat_coal_icon"};
const int[] fuel_strength = { 1, 4 };
const int max_fuel = 1000;

int getFuelIndex(CBlob@ caller)
{
	for (int i = 0; i < fuel_names.length; i++)
	{
		if (caller.hasBlob(fuel_names[i], 1)) return i;
	}
	return -1;
}

void server_addFuel(CBlob@ this, CBlob@ caller)
{
	const int requestedAmount = Maths::Min(250, max_fuel - this.get_s16(fuel_prop));
	if (requestedAmount <= 0) return;

	const int index = getFuelIndex(caller);
	if (index == -1) return;

	const string fuel_name = fuel_names[index];
	const int fuel_amount = fuel_strength[index];

	CBlob@ carried = caller.getCarriedBlob();
	const int callerQuantity = caller.getInventory().getCount(fuel_name) + (carried !is null && carried.getName() == fuel_name ? carried.getQuantity() : 0);
	const int amountToStore = Maths::Min(requestedAmount, callerQuantity);
	if (amountToStore > 0)
	{
		caller.TakeBlob(fuel_name, amountToStore);
		this.add_s16(fuel_prop, amountToStore * fuel_amount);
		this.Sync(fuel_prop, true);
	}
}
