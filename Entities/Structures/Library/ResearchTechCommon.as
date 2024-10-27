// Research 
//Gingerbeard @ July 24, 2024
//Tech Tree system
shared class ResearchTech
{
	string description;
	u8 index;           //upgrade index and sprite frame
	Vec2f offset;       //position on the GUI
	u32 time_to_unlock; //how many seconds it will take to unlock this tech
	u32 time;           //the gametime when this tech will be unlocked
	bool available;     //true if the tech is next to be researched in the tech tree
	bool paused;        //research is paused

	CBitStream requirements;

	ResearchTech@[] connections;
	
	ResearchTech(const string&in description, const u8&in index, Vec2f&in offset, const u32&in time_to_unlock)
	{
		this.description = description;
		this.index = index;
		this.offset = offset;
		this.time_to_unlock = time_to_unlock;
		this.time = 0;
		this.available = false;
		this.paused = false;

		ResearchTech@[]@ TechTree;
		getRules().get("Technology Tree", @TechTree);
		@TechTree[index] = @this;
	}

	bool isResearching() { return time > 0 && !isUnlocked(); }
	bool isUnlocked() { return time >= time_to_unlock; }
	f32 getPercent() { return f32(time) / f32(time_to_unlock); }
	
	bool opEquals(ResearchTech@ tech)
	{
		return this is tech;
	}
}

ResearchTech@[]@ getTechTree()
{
	ResearchTech@[]@ TechTree;
	getRules().get("Technology Tree", @TechTree);
	return TechTree;
}
