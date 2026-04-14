// Migrant brain

#include "MigrantGuide.as"
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
