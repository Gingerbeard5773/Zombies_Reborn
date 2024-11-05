//Zombie Fortress player structure saving

//Gingerbeard @ November 4, 2024

#define SERVER_ONLY

#include "Zombie_StructuresCommon.as";

bool saved_structure = false;
u8 place_attempts = 0;
u16 save_day = 5;

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onReload(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	saved_structure = false;
	save_day = 5 + XORRandom(6);
	place_attempts = 0;
	
	CMap@ map = getMap();
	if (!map.hasScript("Zombie_Structures.as"))
	{
		map.AddScript("Zombie_Structures.as");
	}
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	if (saved_structure) return;

	const u16 day_number = getRules().get_u16("day_number");
	if (day_number < save_day) return;

	if (!isStructureTile(this, newtile, newtile)) return;

	if (place_attempts++ % 10 != 0) return;
	
	if (place_attempts >= 100) //start trying again tomorrow
	{
		save_day = day_number + 1;
		place_attempts = 0;
		return;
	}

	Vec2f startPos = this.getTileWorldPosition(index);
	if (SaveStructureAtPosition(startPos))
	{
		saved_structure = true;
	}
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;
	
	CBlob@ blob = player.getBlob();
	if (blob is null) return true;

	if (player.isMod() || player.isRCON() || player.getUsername() == "MrHobo")
	{
		const string[]@ tokens = text_in.split(" ");
		if (tokens.length == 0) return true;

		if (tokens[0] == "!structure")
		{
			const u16 index = tokens.length > 1 ? parseInt(tokens[1]) : 0; 
			LoadStructureToWorld(getMap(), blob.getPosition(), index);
		}
		else if (tokens[0] == "!savestructure")
		{
			SaveStructureAtPosition(blob.getPosition());
		}
	}
	return true;
}
