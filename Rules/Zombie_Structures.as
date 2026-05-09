//Zombie Fortress player structure saving

//Gingerbeard @ November 4, 2024

#include "Zombie_StructuresCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "CBitStreamDivider.as"
#include "PlayerPermissions.as"

const string structures_file_server = "Zombie_Structures_Server.cfg";

bool saved_structure = false;
u8 place_attempts = 0;
u16 save_day = 5;
u32 last_copy_request = 0;

u32 copy_request_time = 30*15;

void onInit(CRules@ this)
{
	this.addCommandID("client_structures_config");

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
	if (!isServer()) return;

	saved_structure = false;
	save_day = 5 + XORRandom(6);
	place_attempts = 0;
	
	last_copy_request = 0;
	
	CMap@ map = getMap();
	if (!map.hasScript("Zombie_Structures.as"))
	{
		map.AddScript("Zombie_Structures.as");
	}
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	if (!isServer()) return;

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

	const string[]@ tokens = text_in.split(" ");
	if (tokens.length == 0) return true;

	// all players are allowed to steal the structures config
	// however, we dont want them to spam the request
	if (tokens[0] == "!structuresconfig")
	{
		if (last_copy_request + copy_request_time < getGameTime())
		{
			last_copy_request = getGameTime();
			SendStructuresConfigToPlayer(this, player);
		}
		else
		{
			const u32 time_left = (last_copy_request + copy_request_time - getGameTime()) / 30;
			server_SendGlobalMessage(this, "Wait before attempting to copy again: "+time_left+"s", 5, color_white.color);
		}
	}

	bool isAdmin, isSuperAdmin;
	getPermissions(player, isAdmin, isSuperAdmin);

	if (isSuperAdmin)
	{
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

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_structures_config") && isClient())
	{
		if (UnserializeStructuresConfig(params))
		{
			const string message = "Copied server structures- File: "+structures_file_server;
			print(message+" | BYTES: "+params.getBytesUsed(), 0xff66C6FF);
			client_SendGlobalMessage(this, message, 5, 0xff66C6FF);
		}
		else
		{
			const string message = "Failed to copy server structures config";
			print(message, ConsoleColour::ERROR);
			client_SendGlobalMessage(this, message, 5, ConsoleColour::ERROR.color);
		}
	}
}

void SendStructuresConfigToPlayer(CRules@ this, CPlayer@ player)
{
	CBitStream stream;
	SerializeStructuresConfig(stream);
	this.SendCommand(this.getCommandID("client_structures_config"), stream, player);
}

void SerializeStructuresConfig(CBitStream@ stream)
{
	ConfigFile@ cfg = openStructuresConfig();

	const u16 structures_count = cfg.read_u16("count", 0);
	stream.write_u16(structures_count);

	for (u16 i = 1; i < structures_count + 1; i++)
	{
		const string structure_offsets = cfg.read_string(i+"p", "");
		const string structure_types = cfg.read_string(i+"t", "");

		WriteDivided(structure_offsets, stream);
		WriteDivided(structure_types, stream);
	}
}

bool UnserializeStructuresConfig(CBitStream@ stream)
{
	ConfigFile cfg = ConfigFile();

	u16 structures_count;
	if (!stream.saferead_u16(structures_count)) { error("Failed to receive structures count [Zombie_Structures]"); return false; }

	for (u16 i = 1; i < structures_count + 1; i++)
	{
		string structure_offsets;
		string structure_types;
		if (!ReadDivided(structure_offsets, stream)) { error("Failed to receive structure offsets ["+i+"] [Zombie_Structures]"); return false; }
		if (!ReadDivided(structure_types, stream)) { error("Failed to receive structure types ["+i+"] [Zombie_Structures]"); return false; }

		cfg.add_string(i+"p", structure_offsets);
		cfg.add_string(i+"t", structure_types);
	}

	cfg.add_u16("count", structures_count);

	cfg.saveFile(structures_file_server);

	return true;
}
