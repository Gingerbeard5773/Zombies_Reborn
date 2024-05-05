// Factory

#include "ShopCommon.as"
#include "ProductionCommon.as"
#include "TechsCommon.as"
#include "Requirements_Tech.as"
#include "MakeScroll.as"
#include "Help.as"
#include "HallCommon.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"

const string children_destructible_tag = "children destructible";
const string children_destructible_label = "children destruct label";

bool hasTech(CBlob@ this)
{
	return this.get_string("tech name").size() > 0;
}

void onInit(CBlob@ this)
{
	this.Tag("huffpuff production");   // for production.as

	this.addCommandID("upgrade factory");
	this.addCommandID("client_upgrade_factory");
	this.addCommandID("pause production");
	this.addCommandID("unpause production");
	this.addCommandID("attach worker");

	this.set_TileType("background tile", CMap::tile_wood_back);

	SetHelp(this, "help use", "builder", getTranslatedString("$workshop$Convert factory    $KEY_E$"), "", 3);

	if (hasTech(this))
	{
		AddProductionItemsFromTech(this, this.get_string("tech name"));
	}

	this.set_u8("population usage", 1);
	this.set_Vec2f("production offset", Vec2f(-8.0f, 0.0f));
	this.set_s32("gold building amount", 0);
	
	this.getCurrentScript().tickFrequency = 90;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (this.hasTag(worker_tag))
	{
		CBlob@ worker = getWorker(this);
		if (worker !is null && worker.getDistanceTo(this) > this.getRadius())
		{
			CBitStream params;
			params.write_netid(getWorkerID(this));
			this.SendCommand(this.getCommandID(worker_out_cmd), params);
			
			this.Tag("production paused");
			returnWorker(this, getHallsFor(this, BASE_RADIUS), worker);
			this.Untag(worker_tag);
			this.Sync(worker_tag, true);
		
			worker.set_netid("owner id", 0);
		}
		return;
	}

	CBlob@[] overlapping;
	if (!this.getOverlapping(overlapping)) return;

	for (uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		if (!b.hasTag("migrant") || b.isAttached() || b.get_u8("strategy") == Strategy::runaway || b.get_netid("owner id") > 0) continue;
		AttachMigrantToFactory(this, b);
		break;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBitStream params;
	
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && !this.hasTag(worker_tag))
	{
		params.write_netid(carried.getNetworkID());
		caller.CreateGenericButton("$worker_migrant$", Vec2f(0, 0), this, this.getCommandID("attach worker"), getTranslatedString("Assign Worker"), params);
	}
	else if (!hasTech(this) && caller.isOverlapping(this))
	{
		params.write_netid(caller.getNetworkID());
		caller.CreateGenericButton(12, Vec2f(0, 0), this, BuildUpgradeMenu, getTranslatedString("Convert Factory"));
	}
	else if (!this.hasTag(worker_tag))
	{
		CButton@ button = caller.CreateGenericButton("$worker_migrant$", Vec2f(0, 0), this, 0, getTranslatedString("Requires a free worker"));
		if (button !is null)
		{
			button.SetEnabled(false);
		}
	}
}

void AttachMigrantToFactory(CBlob@ this, CBlob@ migrant)
{
	migrant.server_DetachFromAll();
	attachWorker(this, migrant, this.getShape().getHeight());
	this.Tag(worker_tag);
	this.Untag("production paused");
	CBitStream params;
	params.write_netid(migrant.getNetworkID());
	this.SendCommand(this.getCommandID(worker_in_cmd), params);
	migrant.set_Vec2f("brain_destination", this.getPosition());
}

void BuildUpgradeMenu(CBlob@ this, CBlob@ caller)
{
	ScrollSet@ set = getScrollSet("factory options");
	if (caller !is null && set !is null)
	{
		caller.ClearMenus();

		int size = Maths::Ceil(Maths::Sqrt(set.names.length));
		CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, 50.0f), this, Vec2f(size, size), getTranslatedString("Upgrade to..."));
		if (menu !is null)
		{
			menu.deleteAfterClick = true;
			AddButtonsForSet(this, caller, menu, set);
		}
	}
}

void AddButtonsForSet(CBlob@ this, CBlob@ caller, CGridMenu@ menu, ScrollSet@ set)
{
	CInventory@ inv = caller.getInventory();
	for (uint i = 0; i < set.names.length; i++)
	{
		const string defname = set.names[i];
		ScrollDef@ def;
		set.scrolls.get(defname, @def);
		if (def !is null && def.items.length > 0)
		{
			CBitStream params;
			params.write_netid(caller.getNetworkID());
			params.write_string(defname);
			params.write_u16(def.level);
			CGridButton@ button = menu.AddButton("MiniIcons.png", def.scrollFrame, Vec2f(16, 16), getTranslatedString(def.name), this.getCommandID("upgrade factory"), Vec2f(1, 1), params);
			if (button !is null)
			{
				CBitStream reqs, missing;
				AddRequirement(reqs, "blob", "mat_gold", "Gold", def.level);
				SetItemDescription(button, caller, reqs, getTranslatedString(def.name));
				if (!hasRequirements(inv, reqs, missing))
				{
					button.SetEnabled(false);
				}
				else
				{
					// set number of already made factories of this kind
					const s32 team = this.getTeamNum();
					int sameFactoryCount = 0;
					CBlob@[] factories;
					if (getBlobsByName("factory", @factories))
					{
						for (uint step = 0; step < factories.length; ++step)
						{
							CBlob@ factory = factories[step];
							if (factory.getTeamNum() == team)
							{
								const string factoryTechName = factory.get_string("tech name");
								if (factoryTechName == defname)
								{
									sameFactoryCount++;
								}
							}
						}
					}

					button.SetNumber(sameFactoryCount);
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("upgrade factory"))
	{
		if (isServer() && this.get_string("tech name").size() == 0)
		{
			CBlob@ caller = getBlobByNetworkID(params.read_netid());
			if (caller is null) return;

			const string defname = params.read_string();
			const u16 gold_cost = params.read_u16();

			if (caller.getInventory().getCount("mat_gold") < gold_cost) return;
			caller.TakeBlob("mat_gold", gold_cost);
			
			this.set_s32("gold building amount", gold_cost);

			if (this.get_u8("migrants count") > 0 || this.hasTag(worker_tag))
			{
				this.Untag("production paused");
				this.SendCommand(this.getCommandID("unpause production"));
			}
			else
			{
				this.Tag("production paused");
				this.SendCommand(this.getCommandID("pause production"));
			}

			AddProductionItemsFromTech(this, defname);
			CBitStream bs;
			bs.write_string(defname);
			this.SendCommand(this.getCommandID("client_upgrade_factory"), bs); //shitcode,  i dont really care... LOL !!!!
		}
	}
	else if (cmd == this.getCommandID("client_upgrade_factory"))
	{
		const string defname = params.read_string();

		AddProductionItemsFromTech(this, defname);
		this.getSprite().PlaySound("/ConstructShort.ogg");
	}
	else if (cmd == this.getCommandID("pause production") || (hasTech(this) && cmd == this.getCommandID(worker_out_cmd)))
	{
		this.Tag("production paused");
		this.getSprite().PlaySound("/PowerDown.ogg");
	}
	else if (cmd == this.getCommandID("unpause production") || (hasTech(this) && cmd == this.getCommandID(worker_in_cmd)))
	{
		this.Untag("production paused");
		this.getSprite().PlaySound("/PowerUp.ogg");
	}
	else if (cmd == this.getCommandID("attach worker") && isServer())
	{
		CBlob@ worker = getBlobByNetworkID(params.read_netid());
		if (worker !is null && !this.hasTag(worker_tag))
		{
			AttachMigrantToFactory(this, worker);
		}
	}
}
void AddProductionItemsFromTech(CBlob@ this, const string &in defname)
{
	ScrollSet@ set = getScrollSet("factory options");
	ScrollDef@ def;
	set.scrolls.get(defname, @def);
	if (def !is null)
	{
		RemoveProductionItems(this);

		for (uint i = 0 ; i < def.items.length; i++)
		{
			ShopItem @item = def.items[i];
			ShopItem@ s = addProductionItem(this, item.name, item.iconName, item.blobName, item.description, 1, item.spawnInCrate, item.quantityLimit, item.requirements);
			if (s !is null)
			{
				s.ticksToMake = item.ticksToMake * getTicksASecond();
				s.customData = item.customData;
			}
		}

		if (isServer())
		{
			this.set_string("tech name", defname);
			this.Sync("tech name", true);
		}
		this.setInventoryName(def.name + " Factory");
		this.inventoryIconFrame = def.scrollFrame;

		if (isClient())
		{
			RemoveHelps(this, "help use");
			SetHelp(this, "help use", "", getTranslatedString("Check production    $KEY_E$"), "", 2);
		}
	}
}

void RemoveProductionItems(CBlob@ this)
{
	this.clear(TECH_ARRAY);
	this.clear(PRODUCTION_ARRAY);
	this.inventoryIconFrame = 0;
}
