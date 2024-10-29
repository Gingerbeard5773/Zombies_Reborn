//Gingerbeard @ October 10, 2024

//Custom trader shop

#include "Requirements.as";
#include "MakeCrate.as";
#include "MakeSeed.as";
#include "MakeScroll.as";
#include "MaterialCommon.as";
#include "TraderShopCommon.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_shop_buy");
	this.addCommandID("client_shop_buy");
}

void onTick(CBlob@ this)
{
	CBlob@ caller = getLocalPlayerBlob();
	if (caller is null) return;
	
	Shop@ shop;
	if (!this.get("shop", @shop)) return;

	CGridMenu@ menu = getGridMenuByName(shop.description);
	if (menu is null || menu.getOwner() !is this) return;

	if (menu.getButtonsCount() != shop.items.length)
	{
		warn("expected " + menu.getButtonsCount() + " buttons, got " + shop.items.length + " items");
		return;
	}

	for (u8 i = 0; i < shop.items.length; ++i)
	{
		SaleItem@ item = shop.items[i];
		CGridButton@ button = menu.getButtonOfIndex(i);
		button.SetEnabled(true);
		SetShopItemButton(button, this, caller, item);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_shop_buy") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		Shop@ shop;
		if (!this.get("shop", @shop)) return;

		u8 index;
		if (!params.saferead_u8(index)) return;

		SaleItem@ item = shop.items[index];

		CBitStream missing;
		if (!hasRequirements(inv, this.getInventory(), item.requirements, missing)) return;

		if (item.stock == 0) return;
		item.stock--;

		server_TakeRequirements(inv, this.getInventory(), item.requirements);

		CBlob@ blob = server_MakeItem(caller, item, player);
		if (blob !is null)
		{
			if (!caller.server_PutInInventory(blob))
			{
				if (blob.canBePickedUp(caller))
				{
					caller.server_Pickup(blob);
				}
			}
		}

		ShopMadeItemHandle@ onShopMadeItem;
		if (this.get("onShopMadeItem handle", @onShopMadeItem))
		{
			onShopMadeItem(this, caller, blob, item);
		}

		CBitStream stream;
		stream.write_netid(caller.getNetworkID());
		stream.write_netid(blob !is null ? blob.getNetworkID() : 0);
		stream.write_u8(index);
		SerializeShopItems(this, stream);
		this.SendCommand(this.getCommandID("client_shop_buy"), stream);
	}
	else if (cmd == this.getCommandID("client_shop_buy") && isClient())
	{
		u16 caller_netid, blob_netid;
		if (!params.saferead_netid(caller_netid)) return;
		if (!params.saferead_netid(blob_netid)) return;

		CBlob@ caller = getBlobByNetworkID(caller_netid);
		if (caller is null) return;
		
		CBlob@ blob = getBlobByNetworkID(blob_netid);
		
		Shop@ shop;
		if (!this.get("shop", @shop)) return;
		
		u8 index;
		if (!params.saferead_u8(index)) return;

		SaleItem@ item = shop.items[index];
		
		UnserializeShopItems(this, params);
		
		ShopMadeItemHandle@ onShopMadeItem;
		if (this.get("onShopMadeItem handle", @onShopMadeItem))
		{
			onShopMadeItem(this, caller, blob, item);
		}
	}
}

CBlob@ server_MakeItem(CBlob@ caller, SaleItem@ item, CPlayer@ player)
{
	Vec2f position = caller.getPosition();
	
	if (item.type == ItemType::nothing)
	{
		return null;
	}
	else if (item.type == ItemType::material)
	{
		Material::createFor(caller, item.blob_name, item.quantity);
		return null;
	}
	else if (item.type == ItemType::crate)
	{
		CBlob@ blob = server_MakeCrate(item.blob_name, item.name, item.crate_frame_index, caller.getTeamNum(), position);
		return blob;
	}
	else if (item.type == ItemType::seed)
	{
		CBlob@ blob = server_MakeSeed(position, item.blob_name);
		return blob;
	}
	else if (item.type == ItemType::scroll)
	{
		CBlob@ blob = server_MakePredefinedScroll(position, item.blob_name);
		return blob;
	}
	else if (item.type == ItemType::coin)
	{
		player.server_setCoins(player.getCoins() + item.quantity);
		return null;
	}

	CBlob@ blob = server_CreateBlobNoInit(item.blob_name);
	if (blob !is null)
	{
		blob.server_setTeamNum(caller.getTeamNum());
		blob.setPosition(position);
		blob.Init();
	}

	return blob;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	Shop@ shop;
	if (!this.get("shop", @shop)) return;

	if (!shop.available) return;

	CButton@ button = caller.CreateGenericButton(shop.button_icon, shop.button_offset, this, BuildShopMenu, shop.description);
	if (button !is null)
	{
		button.enableRadius = shop.button_enable_radius;
	}
}

void BuildShopMenu(CBlob@ this, CBlob@ caller)
{
	if (!caller.isMyPlayer()) return;

	Shop@ shop;
	if (!this.get("shop", @shop)) return;

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + shop.menu_offset, this, shop.menu_size, shop.description);
	if (menu is null) return;

	menu.deleteAfterClick = false;

	for (u8 i = 0; i < shop.items.length; i++)
	{
		SaleItem@ item = shop.items[i];

		CBitStream stream;
		stream.write_u8(u8(i));

		CGridButton@ button;
		if (item.button_dimensions.x > 0 || item.button_dimensions.y > 0)
			@button = menu.AddButton(item.icon_name, getTranslatedString(item.name), this.getCommandID("server_shop_buy"), item.button_dimensions, stream);
		else
			@button = menu.AddButton(item.icon_name, getTranslatedString(item.name), this.getCommandID("server_shop_buy"), stream);
		
		if (button !is null)
		{
			SetShopItemButton(button, this, caller, item);
		}
	}
}

void SetShopItemButton(CGridButton@ button, CBlob@ this, CBlob@ caller, SaleItem@ item)
{
	button.selectOnClick = true;
	SetItemDescription(button, caller, item.requirements, item.description, this.getInventory());
	AddItemStockDescription(button, item);
}

void AddItemStockDescription(CGridButton@ button, SaleItem@ item)
{
	if (item.stock < 0) return;

	const string color = item.stock > 0 ? "$GREEN$" : "$RED$";
	const string description = item.stock > 0 ? (item.stock+" In stock") : "Out of stock";
	button.hoverText += "\n " + color + description + color;
	if (item.stock <= 0)
		button.SetEnabled(false);
}


/// NETWORKING

void SerializeShopItems(CBlob@ this, CBitStream@ stream)
{
	Shop@ shop;
	if (!this.get("shop", @shop)) return;

	for (u8 i = 0; i < shop.items.length; i++)
	{
		SaleItem@ item = shop.items[i];
		stream.write_s32(item.stock);
	}
}

bool UnserializeShopItems(CBlob@ this, CBitStream@ stream)
{
	Shop@ shop;
	if (!this.get("shop", @shop)) return false;

	for (u8 i = 0; i < shop.items.length; i++)
	{
		SaleItem@ item = shop.items[i];
		if (!stream.saferead_s32(item.stock)) return false;
	}

	return true;
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	SerializeShopItems(this, stream);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	if (!UnserializeShopItems(this, stream))
	{
		error("Failed to access shop data! : "+this.getNetworkID());
		return false;
	}
	return true;
}
