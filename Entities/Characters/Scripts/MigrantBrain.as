// Migrant brain

#include "BrainTask.as"
#include "EatCommon.as"

// Gingerbeard @ June 21, 2025

const string[] first_name =
{
	"William", "Henry", "Richard", "John", "Robert", "Thomas", "Geoffrey", "Walter", "Hugh",
	"Roger", "Stephen", "Edmund", "Alfred", "Baldwin", "Gilbert", "Ralph", "Nicholas", "Simon",
	"Peter", "Martin", "Philip", "Adam", "Bernard", "Raymond", "Giles", "Osbert", "Anselm",
	"Godfrey", "Eustace", "Percival", "Edgar", "Harold", "Leofric", "Cedric", "Wilfred",
	"Roland", "Matthis", "Odo", "Bertram", "Fulk", "Ivo", "Lothar", "Arnulf", "Erik",
	"Sigurd", "Magnus", "Sven", "Ulric", "Gerard", "Theobald", "Thorfinn", "Askeladd",
	"Thorkell", "Einar", "Leif", "Canute", "Sonant", "Golden", "Vamist", "Sinecura"
};

const string[] last_name = 
{
	"Atwood", "Hill", "Brook", "Ford", "Wood", "Field", "Green", "Stone", "Church", "Knight",
	"Squire", "Abbott", "Reeve", "Underhill", "Rivers", "Oakley", "Thorne", "Hawthorn",
	"Blackwood", "Whitehill", "Redford", "Greyfield", "Storm", "Raven", "Fox",
	"Wolf", "Hart", "Boar", "Falcon", "Hawke", "Crow", "Bear", "Ashford", "Brighton",
	"Westwood", "Eastfield", "Northcott", "Southwell", "Langford", "Bracken", "Fenwick", 
	"Marsh", "Reed", "Vale", "Cliff", "Lowell", "Highmoor", "Coldstream", "Rook", "Barrow",
	"Erikson", "Snorresson", "Sigvaldi", "Baldr", "Guy", "Fisher"
};

void onInit(CBlob@ this)
{
	this.Tag("migrant");

	Random rand(this.exists("previous blob netid") ? this.get_u32("previous blob netid") : this.getNetworkID());
	const string name = first_name[rand.NextRanged(first_name.length)] +" "+last_name[rand.NextRanged(last_name.length)];
	this.setInventoryName(name);

	BrainPath pather(this, Path::GROUND);
	this.set("brain_path", @pather);

	addOnPathDestination(this, @onPathDestination);

	TaskManager manager(this);
}

void onReload(CBlob@ this)
{
	BrainPath pather(this, Path::GROUND);
	this.set("brain_path", @pather);
}

void onTick(CBlob@ this)
{
	BrainPath@ pather;
	if (!this.get("brain_path", @pather)) return;

	if ((this.getPlayer() !is null && !this.isBot()) || this.hasTag("sleeper"))
	{
		this.Untag("migrant");
		this.getCurrentScript().tickFrequency = 0;
		pather.EndPath();
		return;
	}
	
	if (this.hasTag("dead"))
	{
		onDie(this);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return;
	}

	if (!isServer()) return;

	pather.Tick();
	pather.SetSuggestedKeys();
	pather.SetSuggestedAimPos();

	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return;

	manager.Tick();
}

void onPathDestination(CBlob@ this, BrainPath@ pather)
{
	BrainTask@ task = getCurrentTask(this);
	if (task is null) return;

	task.onPathDestination();
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (!attached.hasTag("player")) return;

	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return;

	manager.tasks.clear();
}

void onDie(CBlob@ this)
{
	if (!isServer()) return;

	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return;

	manager.tasks.clear();
	manager.Tick();
}

void onRender(CSprite@ this)
{
	if ((!render_paths && g_debug == 0) || g_debug == 5) return;

	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;

	BrainPath@ pather;
	if (!blob.get("brain_path", @pather)) return;

	pather.Render();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("migrant")) return damage * 0.25f;

	return damage;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() >= oldHealth) return;

	AttemptToEat(this);
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	AttemptToEat(this);
}

void AttemptToEat(CBlob@ this)
{
	if (!this.hasTag("migrant")) return;
	
	CInventory@ inventory = this.getInventory();
	for (u16 i = 0; i < inventory.getItemsCount(); i++)
	{
		CBlob@ item = inventory.getItem(i);
		if (!canEat(item)) continue;
		
		const f32 heal = f32(getHealingAmount(item)) * 0.125f; 
		if (this.getHealth() + heal * 0.5f > this.getInitialHealth()) continue;

		Heal(this, item);
	}
}

/// NETWORKING

/*void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return;

	manager.Serialize(stream);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	TaskManager@ manager = getTaskManager(this);
	if (manager is null) return false;

	manager.Unserialize(stream);
	return true;
}*/

/// GUIDE

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.hasTag("migrant")) return;

	CRules@ rules = getRules();
	if (this.getNetworkID() != rules.get_netid("guide netid")) return;

	if (this.getNetworkID() == rules.get_netid("inventory access")) return;

	caller.CreateGenericButton(14, Vec2f(0, 0), this, Callback_AskQuestion, Translate::Help);
}

void Callback_AskQuestion(CBlob@ this, CBlob@ caller)
{
	this.Chat(getRelevantGuideInfo(caller));
}

string getRelevantGuideInfo(CBlob@ caller)
{
	string[] possible =
	{
		Translate::Guide1, Translate::Guide2, Translate::Guide3, Translate::Guide4, Translate::Guide5, Translate::Guide6, Translate::Guide7, 
		Translate::Guide8, Translate::Guide9, Translate::Guide10, Translate::Guide11, Translate::Guide12, Translate::Guide13, 
		Translate::Guide14, Translate::Guide15, Translate::Guide16, Translate::Guide17, Translate::Guide18, Translate::Guide19
	};

	CRules@ rules = getRules();

	CBlob@ library = getBlobByName("library");
	const string library_tip = library is null ? Translate::GuideVogue1 : Translate::GuideVogue2;
	possible.push_back(library_tip);

	CBlob@ sedgwick = getBlobByName("sedgwick");
	if (sedgwick !is null)
	{
		addRelevantInfo(Translate::GuideVogue3, @possible, 10);
	}

	CBlob@ portal = getBlobByName("zombieportal");
	if (portal !is null)
	{
		const string portal_tip = portal.hasTag("portal_activated") ? Translate::GuideVogue7 : Translate::GuideVogue6;
		addRelevantInfo(portal_tip, @possible, 10);
	}

	CBlob@ tim = getBlobByName("tim");
	if (tim !is null)
	{
		addRelevantInfo(Translate::GuideVogue5, @possible, 10);
	}
	else if (rules.get_u16("tim_day") - rules.get_u16("day_number") < 4)
	{
		addRelevantInfo(Translate::GuideVogue4, @possible, 3);
	}

	CInventory@ inv = caller.getInventory();
	if (inv !is null)
	{
		for (u16 i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			const string name = item.exists("scroll defname0") ? item.get_string("scroll defname0") : item.getName();
			const int index = info_item.find(name);
			if (index != -1)
			{
				addRelevantInfo(info_item_description[index], @possible, 10);
			}
		}
	}
	
	return possible[XORRandom(possible.length)];
}

const string[] info_item =
{
	"clone", "sea", "crate", "revive", "health", "carnage", "teleport", "repair",
	"midas", "stone", "holygrenade", "shotgun", "bazooka"
};

const string[] info_item_description =
{
	Translate::GuideItem1, Translate::GuideItem2, Translate::GuideItem3, Translate::GuideItem4,
	Translate::GuideItem5, Translate::GuideItem6, Translate::GuideItem7, Translate::GuideItem8,
	Translate::GuideItem9, Translate::GuideItem10,
	Translate::GuideItem11, Translate::GuideItem12, Translate::GuideItem13
};

void addRelevantInfo(const string&in info, string[]@ possible, const u8&in relevancy)
{
	for (u8 i = 0; i < relevancy; i++)
	{
		possible.push_back(info);
	}
}
