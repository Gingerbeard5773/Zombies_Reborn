#include "Requirements.as";
#include "CraftItemCommon.as";
#include "MaterialCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30; //once a second
	
	this.addCommandID("server_set_crafting");
	this.addCommandID("client_set_crafting");
	this.addCommandID("client_produce_item");
	
	Craft@ craft = getCraft(this);
	if (craft !is null)
	{
		SetPullItems(this, craft);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!isInventoryAccessible(this, caller)) return;
	
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	CButton@ button = caller.CreateGenericButton("$"+this.getName()+"_craft_icon_"+craft.selected+"$", craft.button_offset, this, CraftMenu, Translate::SetRecipe);
}

void CraftMenu(CBlob@ this, CBlob@ caller)
{
	if (!caller.isMyPlayer()) return;

	Craft@ craft = getCraft(this);
	if (craft is null) return;

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), this, craft.menu_size, Translate::Recipes);
	if (menu is null) return;

	for (u8 i = 0; i < craft.items.length; i++)
	{
		CraftItem@ item = craft.items[i];

		CBitStream params;
		params.write_u8(i);
		
		const bool isSelected = craft.selected == i;
		const string recipe_name = item.title.split("\n")[0];
		const string text = (isSelected ? Translate::CurrentRecipe : Translate::SetRecipe) + ": " + recipe_name;

		CGridButton@ butt = menu.AddButton("$"+this.getName()+"_craft_icon_" + i + "$", text, this.getCommandID("server_set_crafting"), params);
		butt.hoverText = item.title + "\n\n" + getButtonRequirementsText(item.reqs, false);
		butt.SetEnabled(!isSelected);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	if (cmd == this.getCommandID("server_set_crafting") && isServer())
	{
		if (!params.saferead_u8(craft.selected)) return;
		craft.time = 0;
		SetPullItems(this, craft);

		CBitStream stream;
		stream.write_u8(craft.selected);
		this.SendCommand(this.getCommandID("client_set_crafting"), stream);
	}
	else if (cmd == this.getCommandID("client_set_crafting") && isClient())
	{
		if (!params.saferead_u8(craft.selected)) return;
		craft.time = 0;
		SetPullItems(this, craft);
	}
	else if (cmd == this.getCommandID("client_produce_item") && isClient())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ blob = getBlobByNetworkID(netid); //null checks go in onProduceItem as blob can be null intentionally
		
		if (!craft.produce_sound.isEmpty())
		{
			this.getSprite().PlaySound(craft.produce_sound);
		}
		
		if (!isServer())
		{
			onProduceItemHandle@ onProduceItem;
			if (this.get("onProduceItem handle", @onProduceItem))
			{
				onProduceItem(this, blob, craft);
			}
		}
	}
}

void SetPullItems(CBlob@ this, Craft@ craft)
{
	if (!this.exists("pull_items")) return;

	CraftItem@ item = craft.items[craft.selected];
	CBitStream bs = item.reqs;
	bs.ResetBitIndex();
	string req, name, friendlyName;

	string[] pull_names;

	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, req, name, friendlyName, 0);
		if (req != "blob") continue;

		pull_names.push_back(name);
	}

	this.set("pull_items", pull_names);
}

void onTick(CBlob@ this)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	CraftItem@ item = craft.items[craft.selected];
	CInventory@ inv = this.getInventory();

	CBitStream missing;
	if (hasRequirements(inv, item.reqs, missing) && craft.can_craft)
	{	
		craft.time += 1;
		if (craft.time >= item.seconds_to_produce * craft.time_modifier)
		{
			if (isServer())
			{
				CBlob@ blob = server_MakeItem(this, item);
				if (blob !is null)
				{
					this.server_PutInInventory(blob);
				}

				server_TakeRequirements(inv, item.reqs);
				
				onProduceItemHandle@ onProduceItem;
				if (this.get("onProduceItem handle", @onProduceItem))
				{
					onProduceItem(this, blob, craft);
				}
				
				CBitStream stream;
				stream.write_netid(blob is null ? 0 : blob.getNetworkID());
				this.SendCommand(this.getCommandID("client_produce_item"), stream);
			}
			
			craft.time = 1;
		}
	}
	else
	{
		craft.time = 0;
	}
}

CBlob@ server_MakeItem(CBlob@ this, CraftItem@ item)
{
	if (item.type == ItemType::nothing)
	{
		return null;
	}
	else if (item.type == ItemType::material)
	{
		Material::createFor(this, item.result_name, item.result_count);
		return null;
	}
	
	CBlob@ mat = server_CreateBlobNoInit(item.result_name);
	if (mat !is null)
	{
		mat.Tag('custom quantity');
		mat.setPosition(this.getPosition());
		mat.server_setTeamNum(this.getTeamNum());
		mat.Init();
		mat.server_SetQuantity(item.result_count);
	}
	return mat;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	CraftItem@ item = craft.items[craft.selected];
	CBitStream bs = item.reqs;
	bs.ResetBitIndex();
	string name;

	while (!bs.isBufferEnd())
	{
		string unused = "";
		ReadRequirement(bs, unused, name, unused, 0);

		if (blob.getName() == name)
		{
			this.server_PutInInventory(blob);
			break;
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return this.getDistanceTo(forBlob) < this.getRadius();
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PopIn");
}

///NETWORK

void onSendCreateData(CBlob@ this, CBitStream@ params)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	params.write_u8(craft.selected);
	params.write_u16(craft.time);
	params.write_bool(craft.can_craft);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ params)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return false;

	if (!params.saferead_u8(craft.selected)) return false;
	if (!params.saferead_u16(craft.time)) return false;
	if (!params.saferead_bool(craft.can_craft)) return false;

	return true;
}
