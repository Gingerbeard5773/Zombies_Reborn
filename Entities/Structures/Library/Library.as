//Gingerbeard @ July 24, 2024

#include "Requirements.as"
#include "Zombie_TechnologyCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

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
}

void onTick(CBlob@ this)
{
	Technology@ researched = getResearching(this);
	if (researched is null) return;
	
	//each worker decreases tickFrequency by 1 tick.
	//1 tick is about 3.33% of a second, so 3 workers is 10% reduction.
	this.getCurrentScript().tickFrequency = 30 - this.get_u8("current_worker_count");

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

			Statistics::server_Add("technologies_researched", 1, player);

			Achievement::server_Unlock(Achievement::Bookworm, player);

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
	
	if (isServer() && isTechTreeCompleted())
	{
		Achievement::server_Unlock(Achievement::Librarian);
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

bool isTechTreeCompleted()
{
	Technology@[]@ TechTree = getTechTree();
	for (u8 i = 0; i < TechTree.length; i++)
	{
		Technology@ tech = TechTree[i];
		if (tech is null) continue;
		
		if (!tech.completed) return false;
	}
	return true;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() != this.getTeamNum()) return;

	if (this.getDistanceTo(caller) <= this.getRadius())
	{
		caller.CreateGenericButton(27, Vec2f_zero, this, Callback_Research, getTranslatedString("Research"));
	}
}

void Callback_Research(CBlob@ this, CBlob@ caller)
{
	this.Tag("show research");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	SetStandardWorkerPosition(this, attached, attachedPoint);
}

void SetStandardWorkerPosition(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.name != "WORKER") return;

	Random rand(this.getNetworkID() + attached.getNetworkID());
	const f32 width = int(rand.NextRanged(this.getWidth()*0.5f)) - (this.getWidth() * 0.25f);
	Vec2f offset = Vec2f(width, (this.getHeight() - attached.getHeight()) * 0.5f);

	attachedPoint.offsetZ = 25.0f;
	attachedPoint.offset = offset;
}
