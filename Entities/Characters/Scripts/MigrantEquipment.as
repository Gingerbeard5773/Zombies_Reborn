// Migrant Equipment

// Equipment for bots must be done via an outside button as it cannot be done in their inventory

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	const u16 inv_access = getRules().get_u16("inventory access");
	if (this.getNetworkID() != inv_access) return;

	u16[] ids;
	if (!this.get("equipment_ids", ids)) return;

	CBlob@ carried = caller.getCarriedBlob();
	if (carried is null || !carried.exists("equipment_slot")) return;

	const string icon = carried.exists("equipment_icon") ? carried.get_string("equipment_icon") : "$"+carried.getName()+"$";
	const string hover = Translate("Equip").replace("{ITEM}", carried.getInventoryName());
	caller.CreateGenericButton(icon, Vec2f(0, -8), this, Callback_EquipBot, hover);
}

void Callback_EquipBot(CBlob@ this, CBlob@ caller)
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried is null || !carried.exists("equipment_slot")) return;

	getHUD().ClearMenus();

	const u8 index = equipment.find(carried.get_string("equipment_slot"));
	if (index == -1) return;

	CBitStream stream;
	stream.write_u8(index);
	stream.write_netid(carried.getNetworkID());

	this.SendCommand(this.getCommandID("server_equip"), stream);
}
