//Gingerbeard @ July 24, 2024

#include "AssignWorkerCommon.as";
#include "Requirements.as";
#include "Zombie_TechnologyCommon.as";
#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	AddIconToken("$TECHNOLOGY_HEADER$", "TechnologyHeader.png", Vec2f(106, 24), 0);

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.addCommandID("server_research");
	this.addCommandID("client_research");
	this.addCommandID("client_finish_technology");
	
	this.getCurrentScript().tickFrequency = 30; //once a second
	
	this.set_s32("researching", -1);
	
	this.set_u8("maximum_worker_count", 3);
	this.Tag("auto_assign_worker");
	addOnAssignWorker(this, @onAssignWorker);
	addOnUnassignWorker(this, @onUnassignWorker);
}

void onTick(CBlob@ this)
{
	Technology@ researched = getResearching(this);
	if (researched is null) return;
	
	//each worker decreases tickFrequency by 1 tick.
	//1 tick is about 3.33% of a second, so 3 workers is 10% reduction.
	this.getCurrentScript().tickFrequency = 30 - getWorkers(this).length;

	researched.time++;
	researched.paused = false;
	
	if (isServer() && researched.time >= researched.time_to_unlock && researched.available)
	{
		onFinishTechnology(researched);

		CBitStream stream;
		stream.write_u8(researched.index);
		this.SendCommand(this.getCommandID("client_finish_technology"), stream);
	}
}

void onDie(CBlob@ this)
{
	Technology@ researched = getResearching(this);
	if (researched !is null)
		researched.paused = true;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_research") && isServer())
	{
		Technology@ researched = getResearching(this);
		if (researched !is null) return;

		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		CInventory@ inventory = caller.getInventory();
		if (inventory is null) return;
		
		u8 index;
		if (!params.saferead_u8(index)) return;
		
		Technology@ tech = getTech(index);
		if (tech is null) return;
		
		const bool duplicate = tech.isResearching();
		
		CBitStream missing;
		if (hasRequirements(inventory, tech.requirements, missing) || duplicate)
		{
			if (!duplicate)
			{
				server_TakeRequirements(inventory, tech.requirements);
			}

			SetResearching(this, tech);
			CBitStream stream;
			stream.write_u8(index);
			this.SendCommand(this.getCommandID("client_research"), stream);
		}
	}
	else if (cmd == this.getCommandID("client_research") && isClient())
	{
		u8 index;
		if (!params.saferead_u8(index)) return;

		SetResearching(this, getTech(index));
	}
	else if (cmd == this.getCommandID("client_finish_technology") && isClient())
	{
		u8 index;
		if (!params.saferead_u8(index)) return;

		Technology@ tech = getTech(index);
		if (tech is null) return;
		
		if (!isServer())
		{
			onFinishTechnology(tech);
		}

		Sound::Play("/ResearchComplete.ogg");

		const string tech_completed = Translate::TechComplete.replace("{TECH}", name(tech.description));
		client_SendGlobalMessage(getRules(), tech_completed, 6, SColor(0xffa293ff)); 
		print(tech_completed);
	}
}

void SetResearching(CBlob@ this, Technology@ tech)
{
	if (tech is null) return;
	tech.time++;
	this.set_s32("researching", tech.index);
}

void onFinishTechnology(Technology@ tech)
{
	tech.completed = true;
	tech.available = false;

	CBlob@[] libraries;
	getBlobsByName("library", @libraries);
	for (u16 i = 0; i < libraries.length; i++)
	{
		CBlob@ library = libraries[i];
		if (library.get_s32("researching") == tech.index)
		{
			library.set_s32("researching", -1);
		}
	}

	for (u8 i = 0; i < tech.connections.length; i++)
	{
		tech.connections[i].available = true;
	}
	
	CRules@ rules = getRules();
	onTechnologyRulesHandle@ onTechnologyRules;
	if (rules.get("onTechnology handle", @onTechnologyRules))
	{
		onTechnologyRules(rules, tech.index);
	}

	/*CBlob@[] blobs;
	getBlobs(@blobs);
	
	for (u16 i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		onTechnologyHandle@ onTechnology;
		if (blob.get("onTechnology handle", @onTechnology))
		{
			onTechnology(blob, tech.index);
		}
	}*/
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() != this.getTeamNum()) return;

	if (!AssignWorkerButton(this, caller) && this.getDistanceTo(caller) <= this.getRadius())
	{
		UnassignWorkerButton(this, caller, Vec2f(0, -14));

		caller.CreateGenericButton(27, Vec2f_zero, this, Callback_Research, getTranslatedString("Research"));
	}
}

void Callback_Research(CBlob@ this, CBlob@ caller)
{
	this.Tag("show research");
}

void onAssignWorker(CBlob@ this, CBlob@ worker)
{
	SetStandardWorkerPosition(this, worker);
}

void onUnassignWorker(CBlob@ this, CBlob@ worker)
{
	worker.server_DetachFrom(this);
}
