//trader specific shop menu
// customized to enable stocking and capped shop item-count

// properties:
//      shop offset - Vec2f - used to offset things bought that spawn into the world, like vehicles

#include "Requirements_Trader.as";
#include "MakeCrate.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("shop buy");
	this.addCommandID("shop made item");

	if (!this.exists("shop available"))
		this.set_bool("shop available", true);
	if (!this.exists("shop offset"))
		this.set_Vec2f("shop offset", Vec2f_zero);
	if (!this.exists("shop menu size"))
		this.set_Vec2f("shop menu size", Vec2f(7, 7));
	if (!this.exists("shop description"))
		this.set_string("shop description", "Workbench");
	if (!this.exists("shop icon"))
		this.set_u8("shop icon", 15);
	if (!this.exists("shop offset is buy offset"))
		this.set_bool("shop offset is buy offset", false);

	if (!this.exists("shop button radius"))
	{
		CShape@ shape = this.getShape();
		this.set_u8("shop button radius", shape !is null ? Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight()) / 2) : 16);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || caller.isAttachedTo(this)) return;

	if (this.get_bool("shop available") && !this.hasTag("shop disabled"))
	{
		CButton@ button = caller.CreateGenericButton(
			this.get_u8("shop icon"),                                // icon token
			this.get_Vec2f("shop offset"),                           // button offset
			this,                                                    // shop blob
			createMenu,                                              // func callback
			getTranslatedString(this.get_string("shop description")) // description
		);

		button.enableRadius = this.get_u8("shop button radius");
	}
}


void createMenu(CBlob@ this, CBlob@ caller)
{
	if (this.hasTag("shop disabled")) return;

	BuildShopMenu(this, caller, this.get_string("shop description"), Vec2f(0, 0), this.get_Vec2f("shop menu size"));
}

const bool isInRadius(CBlob@ this, CBlob@ caller)
{
	Vec2f offset = this.get_bool("shop offset is buy offset") ? this.get_Vec2f("shop offset") : Vec2f_zero;
	
	return ((this.getPosition() + Vec2f((this.isFacingLeft() ? -2 : 2)*offset.x, offset.y) - caller.getPosition()).Length() < caller.getRadius() / 2 + this.getRadius());
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop buy"))
	{
		if (this.hasTag("shop disabled")) return;

		u16 callerID;
		if (!params.saferead_u16(callerID)) return;
		
		const bool spawnToInventory = params.read_bool();
		const bool spawnInCrate = params.read_bool();
		const bool producing = params.read_bool();
		const string blobName = params.read_string();
		const u8 s_index = params.read_u8();
		const bool hotkey = params.read_bool();

		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null) return;
		CInventory@ inv = caller.getInventory();

		if (this.getHealth() <= 0)
		{
			caller.ClearMenus();
			return;
		}
		
		if (!isServer()) return; //only do this on server

		if (inv !is null && isInRadius(this, caller))
		{
			ShopItem[]@ shop_items;
			if (!this.get(SHOP_ARRAY, @shop_items)) return;
			
			if (s_index >= shop_items.length) return;
			ShopItem@ s = shop_items[s_index];

			bool tookReqs = false;

			// try taking from the caller + this shop first
			CBitStream missing;
			if (hasRequirements(inv, this.getInventory(), s, missing))
			{
				server_TakeRequirements(inv, this.getInventory(), s);
				tookReqs = true;
			}

			if (tookReqs)
			{
				if (s.spawnNothing)
				{
					CBitStream params;
					params.write_netid(caller.getNetworkID());
					params.write_netid(0);
					params.write_string(blobName);
					params.write_u8(s_index);
					this.SendCommand(this.getCommandID("shop made item"), params);
				}
				else
				{
					Vec2f spawn_offset = Vec2f();

					if (this.exists("shop offset")) { Vec2f _offset = this.get_Vec2f("shop offset"); spawn_offset = Vec2f(2*_offset.x, _offset.y); }
					if (this.isFacingLeft()) { spawn_offset.x *= -1; }
					CBlob@ newlyMade = null;

					if (spawnInCrate)
					{
						CBlob@ crate = server_MakeCrate(blobName, s.name, s.crate_icon, caller.getTeamNum(), caller.getPosition());

						if (crate !is null)
						{
							if (spawnToInventory && caller.canBePutInInventory(crate))
							{
								caller.server_PutInInventory(crate);
							}
							else
							{
								caller.server_Pickup(crate);
							}
							@newlyMade = crate;
						}
					}
					else
					{
						CBlob@ blob = server_CreateBlob(blobName, caller.getTeamNum(), this.getPosition() + spawn_offset);
						CInventory@ callerInv = caller.getInventory();
						if (blob !is null)
						{
							const bool pickable = blob.getAttachments() !is null && blob.getAttachments().getAttachmentPointByName("PICKUP") !is null;
							if (spawnToInventory)
							{
								if (!blob.canBePutInInventory(caller))
								{
									caller.server_Pickup(blob);
								}
								else if (!callerInv.isFull())
								{
									caller.server_PutInInventory(blob);
								}
								else if (pickable)
								{
									caller.server_Pickup(blob);
								}
							}
							else
							{
								CBlob@ carried = caller.getCarriedBlob();
								if (carried is null && pickable)
								{
									caller.server_Pickup(blob);
								}
								else if (blob.canBePutInInventory(caller) && !callerInv.isFull())
								{
									caller.server_PutInInventory(blob);
								}
								else if (pickable)
								{
									caller.server_Pickup(blob);
								}
							}
							@newlyMade = blob;
						}
					}

					if (newlyMade !is null)
					{
						newlyMade.set_u16("buyer", caller.getPlayer().getNetworkID());

						CBitStream params;
						params.write_netid(caller.getNetworkID());
						params.write_netid(newlyMade.getNetworkID());
						params.write_string(blobName);
						params.write_u8(s_index);
						this.SendCommand(this.getCommandID("shop made item"), params);
					}
				}
			}
		}
	}
}

//helper for building menus of shopitems

void addShopItemsToMenu(CBlob@ this, CGridMenu@ menu, CBlob@ caller)
{
	ShopItem[]@ shop_items;

	if (this.get(SHOP_ARRAY, @shop_items))
	{
		for (uint i = 0 ; i < shop_items.length; i++)
		{
			ShopItem@ s = shop_items[i];
			if (s is null || caller is null) continue;
			
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			params.write_bool(s.spawnToInventory);
			params.write_bool(s.spawnInCrate);
			params.write_bool(s.producing);
			params.write_string(s.blobName);
			params.write_u8(u8(i));
			params.write_bool(false);

			CGridButton@ button;

			if (s.customButton)
				@button = menu.AddButton(s.iconName, getTranslatedString(s.name), this.getCommandID("shop buy"), Vec2f(s.buttonwidth, s.buttonheight), params);
			else
				@button = menu.AddButton(s.iconName, getTranslatedString(s.name), this.getCommandID("shop buy"), params);

			if (button !is null)
			{
				button.selectOnClick = true;

				SetItemDescription(button, caller, getTranslatedString(s.description), this.getInventory(), s);
			}
		}
	}
}

void BuildShopMenu(CBlob@ this, CBlob @caller, string description, Vec2f offset, Vec2f slotsAdd)
{
	if (caller is null || !caller.isMyPlayer()) return;

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + offset, this, Vec2f(slotsAdd.x, slotsAdd.y), getTranslatedString(description));
	if (menu !is null)
	{
		if (!this.hasTag(SHOP_AUTOCLOSE))
			menu.deleteAfterClick = false;

		addShopItemsToMenu(this, menu, caller);
	}
}
