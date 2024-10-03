// Factory

#include "FactoryProductionCommon.as"
#include "Requirements.as"
#include "Help.as"
#include "MiniIconsInc.as"
#include "AssignWorkerCommon.as"

Vec2f menu_size(3, 4);

const f32 building_gold_percent = 0.80f; //percent of the gold we get back from the building when it is destroyed

void onInit(CBlob@ this)
{
	this.Tag("huffpuff production");

	this.addCommandID("server_upgrade_factory");
	this.addCommandID("client_upgrade_factory");

	this.set_TileType("background tile", CMap::tile_wood_back);

	SetHelp(this, "help use", "builder", getTranslatedString("$workshop$Convert factory    $KEY_E$"), "", 3);

	this.set_Vec2f("production offset", Vec2f(-8.0f, 0.0f));
	this.set_s32("gold building amount", 0);
	
	addOnAssignWorker(this, @onAssignWorker);
	addOnUnassignWorker(this, @onUnassignWorker);
	
	SetupProductionSet();
}

void SetupProductionSet()
{
	if (getRules().exists("factory_production_set")) return;

	Production@[] production_set;
	{
		Production tech("Bombs", FactoryFrame::military_basics);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 35);
		tech.addProductionItem("mat_bombs", "Bombs", "", 10, 5);
		production_set.push_back(tech);
	}
	{
		Production tech("Catapult", FactoryFrame::catapult);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 50);
		tech.addProductionItem("catapult", "Catapult", "", 60, 1, Product::crate);
		production_set.push_back(tech);
	}
	{
		Production tech("Ballista", FactoryFrame::ballista);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 100);
		tech.addProductionItem("ballista", "Ballista", "", 60, 1, Product::crate);
		tech.addProductionItem("mat_bolts", "Ballista Bolts", "", 60, 1);
		tech.addProductionItem("mat_bomb_bolts", "Ballista Shells", "", 60, 1);
		production_set.push_back(tech);
	}
	{
		Production tech("Bomber", 7);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 150);
		tech.addProductionItem("bomber", "Bomber", "", 80, 1, Product::crate);
		production_set.push_back(tech);
	}
	{
		Production tech("Tank", 11);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 150);
		tech.addProductionItem("tank", "Tank", "", 80, 1, Product::crate);
		production_set.push_back(tech);
	}
	{
		Production tech("Mounted Bow", FactoryFrame::mounted_bow);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 50);
		tech.addProductionItem("mounted_bow", "Mounted Bow", "", 40, 2, Product::crate);
		production_set.push_back(tech);
	}
	{
		Production tech("Kegs", FactoryFrame::explosives);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 80);
		tech.addProductionItem("keg", "Kegs", "", 40, 1);
		production_set.push_back(tech);
	}
	{
		Production tech("Mines", 18);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 50);
		tech.addProductionItem("mine", "Mines", "", 20, 4);
		production_set.push_back(tech);
	}
	{
		Production tech("Pyrotechnics", FactoryFrame::pyro);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 50);
		tech.addProductionItem("molotov", "Molotov", "", 25, 2);
		tech.addProductionItem("mat_molotovarrows", "Molotov Arrows", "", 35, 2);
		production_set.push_back(tech);
	}
	{
		Production tech("Water Ammo", FactoryFrame::water_ammo);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 25);
		tech.addProductionItem("mat_waterarrows", "Water Arrows", "", 25, 3);
		tech.addProductionItem("mat_waterbombs", "Water Bombs", "", 25, 3);
		production_set.push_back(tech);
	}
	{
		Production tech("Bomb Arrows", FactoryFrame::expl_ammo);
		AddRequirement(tech.reqs, "blob", "mat_gold", "Gold", 50);
		tech.addProductionItem("mat_bombarrows", "Bomb Arrows", "", 35, 4);
		production_set.push_back(tech);
	}
	getRules().set("factory_production_set", production_set);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > this.getRadius()) return;

	if (!this.exists("production"))
	{
		caller.CreateGenericButton(12, Vec2f(0, 0), this, BuildUpgradeMenu, getTranslatedString("Convert Factory"));
	}
	else if (!AssignWorkerButton(this, caller) && !UnassignWorkerButton(this, caller, Vec2f(0, -14)))
	{
		CButton@ button = caller.CreateGenericButton("$worker_migrant$", Vec2f(0, 0), this, 0, "Requires a worker");
		if (button !is null)
		{
			button.SetEnabled(false);
		}
	}
}

void BuildUpgradeMenu(CBlob@ this, CBlob@ caller)
{
	caller.ClearMenus();

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, 50.0f), this, menu_size, getTranslatedString("Upgrade to..."));
	if (menu is null) return;

	menu.deleteAfterClick = true;
	AddButtonsForSet(this, caller, menu);
}

void AddButtonsForSet(CBlob@ this, CBlob@ caller, CGridMenu@ menu)
{
	Production@[]@ production_set;
	if (!getRules().get("factory_production_set", @production_set)) return;

	CInventory@ inv = caller.getInventory();
	for (u8 i = 0; i < production_set.length; i++)
	{
		Production@ production = production_set[i];
		
		CBitStream stream;
		stream.write_u8(i);
		CGridButton@ button = menu.AddButton("MiniIcons.png", production.frame, Vec2f(16, 16), getTranslatedString(production.name), this.getCommandID("server_upgrade_factory"), Vec2f(1, 1), stream);
		if (button is null) continue;

		CBitStream missing;
		SetItemDescription(button, caller, production.reqs, getTranslatedString(production.name));
		if (!hasRequirements(inv, production.reqs, missing))
		{
			button.SetEnabled(false);
		}
		else
		{
			// set number of already made factories of this kind
			const s32 team = this.getTeamNum();
			int sameFactoryCount = 0;
			CBlob@[] factories;
			getBlobsByName("factory", @factories);

			for (u16 f = 0; f < factories.length; ++f)
			{
				CBlob@ factory = factories[f];
				if (factory.getTeamNum() != team || !factory.exists("production")) continue;
				
				Production@ factory_production;
				if (!factory.get("production", @factory_production)) continue;
				
				if (factory_production.name == production.name)
				{
					sameFactoryCount++;
				}
			}

			button.SetNumber(sameFactoryCount);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	Production@[]@ production_set;
	if (!getRules().get("factory_production_set", @production_set)) return;

	if (cmd == this.getCommandID("server_upgrade_factory") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		const u8 index = params.read_u8();
		if (index >= production_set.length)
		{
			error("Production Set length does not match index! :: Factory.as, server_upgrade_factory");
			return;
		}
		Production@ production = production_set[index];
		
		CBitStream missing;
		if (!hasRequirements(inv, production.reqs, missing)) return;
		
		server_TakeRequirements(inv, production.reqs);
		
		this.Tag("auto_assign_worker");
		
		Production factory_production(production);
		factory_production.ResetProduction();
		this.set("production", @factory_production);
		
		string req, blobName, friendlyName;
		u16 quantity = 0;
		production.reqs.ResetBitIndex();
		while (!production.reqs.isBufferEnd())
		{
			ReadRequirement(production.reqs, req, blobName, friendlyName, quantity);
			if (blobName == "mat_gold")
			{
				this.set_s32("gold building amount", quantity * building_gold_percent);
				break;
			}
		}

		CBitStream stream;
		stream.write_u8(index);
		this.SendCommand(this.getCommandID("client_upgrade_factory"), stream);
	}
	else if (cmd == this.getCommandID("client_upgrade_factory") && isClient())
	{
		const u8 index = params.read_u8();
		if (index >= production_set.length)
		{
			error("Production Set length does not match index! :: Factory.as, client_upgrade_factory");
			return;
		}

		Production factory_production(production_set[index]);
		factory_production.ResetProduction();
		this.set("production", @factory_production);
		
		RemoveHelps(this, "help use");
		SetHelp(this, "help use", "", getTranslatedString("Check production    $KEY_E$"), "", 2);

		this.getSprite().PlaySound("/ConstructShort.ogg");
	}
}

void onAssignWorker(CBlob@ this, CBlob@ worker)
{
	SetStandardWorkerPosition(this, worker);
	SetWorkerStatic(worker, true);

	this.getSprite().PlaySound("/PowerUp.ogg");
	this.set_bool("can produce", true);
	
	if (isServer())
	{
		Production@ production;
		if (!this.get("production", @production)) return;
		
		for (u8 i = 0; i < production.production_items.length; i++)
		{
			ProductionItem@ item = production.production_items[i];
			if (item.produced.length >= item.maximum_produced) continue;

			item.next_time_to_produce = getGameTime() + item.seconds_to_produce*30;
			
			CBitStream stream;
			stream.write_u8(i);
			stream.write_u32(item.next_time_to_produce);
			this.SendCommand(this.getCommandID("client_set_produce_time"), stream);
		}
	}
}

void onUnassignWorker(CBlob@ this, CBlob@ worker)
{
	SetWorkerStatic(worker, false);

	this.getSprite().PlaySound("/PowerDown.ogg");
	this.set_bool("can produce", false);
}

void SetStandardWorkerPosition(CBlob@ this, CBlob@ worker)
{
	Random rand(this.getNetworkID() + worker.getNetworkID());
	const f32 width = int(rand.NextRanged(this.getWidth()*0.5f)) - (this.getWidth() * 0.25f);
	Vec2f offset = Vec2f(width, (this.getHeight() - worker.getHeight()) * 0.5f);
	worker.setPosition(this.getPosition() + offset);
}
