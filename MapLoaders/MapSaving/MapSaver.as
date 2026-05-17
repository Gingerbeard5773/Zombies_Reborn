// SonantDread & Gingerbeard @ November 14th 2024

/*
 Map Saving
 This tool saves the entire map so that it can be played at a later time.
 No longer will you have to worry about all your progress being lost due to crashes or network outages,
 as you can just simply save the game and return later.

 For Zombies Reborn, we autosave at the beginning of each day. (LoadSavedRules.as)
 If the server dies, the autosave will automatically load on the next startup.
 
 Errors from this script typically mean that a save file is corrupted or outdated
*/

#include "MapSaverCommon.as"
#include "SaveFileCommon.as"
#include "Zombie_TechnologyCommon.as"
#include "EquipmentCommon.as"
#include "BrainTask.as"

// store tiles using run line encoding
string SerializeTileData(CMap@ map)
{
	string map_data = "";

	u16 last_type = map.getTile(0).type;
	u32 tile_count = 1;
	const u32 tilemapsize = map.tilemapheight * map.tilemapwidth;
	for (u32 i = 1; i < tilemapsize; i++)
	{
		const u16 type = map.getTile(i).type;
		if (type == last_type)
		{
			tile_count++;
		}
		else
		{
			map_data += last_type + " " + tile_count + ";";
			last_type = type;
			tile_count = 1;
		}
	}
	map_data += last_type + " " + tile_count + ";";

	return map_data;
}

// store dirt background using run line encoding
string SerializeDirtData(CMap@ map)
{
	string map_data = "";

	bool was_dirt = map.getTile(0).dirt == 80;
	u32 tile_count = 1;
	const u32 tilemapsize = map.tilemapheight * map.tilemapwidth;
	for (u32 i = 1; i < tilemapsize; i++)
	{
		const bool is_dirt = map.getTile(i).dirt == 80;
		if (is_dirt == was_dirt)
		{
			tile_count++;
		}
		else
		{
			map_data += (was_dirt ? "1" : "0") + " " + tile_count + ";";
			was_dirt = is_dirt;
			tile_count = 1;
		}
	}
	map_data += (was_dirt ? "1" : "0") + " " + tile_count + ";";

	return map_data;
}

// store water using run line encoding
string SerializeWaterData(CMap@ map)
{
	string map_data = "";

	bool was_water = map.isInWater(map.getTileWorldPosition(0));
	u32 tile_count = 1;
	const u32 tilemapsize = map.tilemapheight * map.tilemapwidth;
	for (u32 i = 1; i < tilemapsize; i++)
	{
		const bool has_water = map.isInWater(map.getTileWorldPosition(i));
		if (was_water == has_water)
		{
			tile_count++;
		}
		else
		{
			map_data += (was_water ? "1" : "0") + " " + tile_count + ";";
			was_water = has_water;
			tile_count = 1;
		}
	}
	map_data += (was_water ? "1" : "0") + " " + tile_count + ";";

	return map_data;
}

string SerializeBlobData(u16[]@ saved_netids)
{
	CBlob@[] blobs;
	getBlobs(@blobs);
	string blob_data = "";

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!canSaveBlob(blob)) continue;

		saved_netids.push_back(blob.getNetworkID());

		BlobDataHandler@ handler = getBlobHandler(blob.getName());
		const string data = handler.Serialize(blob);
		if (!data.isEmpty())
		{
			blob_data += data + ";"; // extra semicolon to seperate each blob
		}
	}

	return blob_data;
}

string SerializeInventoryData(u16[]@ saved_netids)
{
	string inventory_data;

	for (u16 i = 0; i < saved_netids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(saved_netids[i]);
		if (blob is null) continue;

		CBlob@ parent = blob.getInventoryBlob();
		if (parent is null) continue;

		const int parent_index = saved_netids.find(parent.getNetworkID());
		if (parent_index == -1) continue;

		inventory_data += i + " " + parent_index + ";";
	}

	return inventory_data;
}

string SerializeAttachmentData(u16[]@ saved_netids)
{
	string attachment_data;

	for (u16 i = 0; i < saved_netids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(saved_netids[i]);
		if (blob is null) continue;

		AttachmentPoint@[] aps;
		if (!blob.getAttachmentPoints(@aps)) continue;

		for (u16 a = 0; a < aps.length; a++)
		{
			AttachmentPoint@ ap = aps[a];
			CBlob@ occupied = ap.getOccupied();
			if (occupied is null) continue;

			const int occupied_index = saved_netids.find(occupied.getNetworkID());
			if (occupied_index == -1) continue;

			attachment_data += i + " " + occupied_index + " " + a + ";";
		}
	}

	return attachment_data;
}

string SerializeDamageOwnerPlayerData(u16[]@ saved_netids)
{
	string owner_data;

	string[] player_names;
	u16[][] blob_indexes;

	for (u16 i = 0; i < saved_netids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(saved_netids[i]);
		if (blob is null) continue;

		string username = blob.exists("damage_owner") ? blob.get_string("damage_owner") : "";

		CPlayer@ player = blob.getDamageOwnerPlayer();
		if (player !is null && !player.isBot() && blob !is player.getBlob())
		{
			username = player.getUsername();
		}

		if (username.isEmpty()) continue;

		int player_index = player_names.find(username);
		if (player_index == -1)
		{
			player_names.push_back(username);
			player_index = player_names.length - 1;
			blob_indexes.set_length(player_names.length);
		}

		blob_indexes[player_index].push_back(i);
	}
	
	for (int i = 0; i < player_names.length; i++)
	{
		if (blob_indexes[i].length == 0) continue;

		owner_data += player_names[i] + "{";

		for (int b = 0; b < blob_indexes[i].length; b++)
		{
			owner_data += blob_indexes[i][b] + ";";
		}

		owner_data += "}";
	}

	return owner_data;
}

string SerializeEquipmentData(u16[]@ saved_netids)
{
	string equipment_data;

	for (u16 i = 0; i < saved_netids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(saved_netids[i]);
		if (blob is null) continue;

		u16[] ids;
		if (!blob.get("equipment_ids", ids)) continue;

		for (u16 e = 0; e < ids.length; e++)
		{
			CBlob@ equippedblob = getBlobByNetworkID(ids[e]);
			if (equippedblob is null) continue;

			const int equipped_index = saved_netids.find(equippedblob.getNetworkID());
			if (equipped_index == -1) continue;

			equipment_data += i + " " + equipped_index + " " + e + ";";
		}
	}

	return equipment_data;
}

string SerializeTaskData(u16[]@ saved_netids)
{
	string task_data;

	for (u16 i = 0; i < saved_netids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(saved_netids[i]);
		if (blob is null) continue;

		TaskManager@ manager = getTaskManager(blob);
		if (manager is null || manager.tasks.length <= 0) continue;
		
		task_data += i + ";";
		task_data += manager.index + ";";
		task_data += "{";

		for (int t = 0; t < manager.tasks.length; t++)
		{
			task_data += manager.tasks[t].SerializeString(saved_netids);

			if (t < manager.tasks.length - 1) task_data += "|";
		}

		task_data += "}";
	}

	return task_data;
}

string SerializeTechTree()
{
	string tech_data = "";
	Technology@[]@ techTree = getTechTree();

	for (u8 i = 0; i < techTree.length; i++)
	{
		Technology@ tech = techTree[i];
		if (tech is null) continue;

		tech_data += tech.time + ";";
		tech_data += (tech.available ? 1 : 0) + ";";
		tech_data += (tech.paused ? 1 : 0) + ";";
		tech_data += (tech.completed ? 1 : 0) + ";";
	}
	return tech_data;
}

void SaveMap(CRules@ this, CMap@ map, const string&in save_slot = "AutoSave")
{
	InitializeBlobHandlers();

	ConfigFile@ config = ConfigFile();
	SaveFile@ save = SaveFile();

	// collect all map data
	save.map_dimensions = map.tilemapwidth + ";" + map.tilemapheight;
	save.map_data = SerializeTileData(map);
	save.dirt_data = SerializeDirtData(map);
	save.water_data = SerializeWaterData(map);

	// collect all blob data
	u16[] saved_netids;
	save.blob_data = SerializeBlobData(@saved_netids);
	save.inventory_data = SerializeInventoryData(@saved_netids);
	save.attachment_data = SerializeAttachmentData(@saved_netids);
	save.owner_data = SerializeDamageOwnerPlayerData(@saved_netids);
	save.equipment_data = SerializeEquipmentData(@saved_netids);
	save.task_data = SerializeTaskData(@saved_netids);

	// collect rules data
	save.day_number = this.exists("day_number") ? this.get_u16("day_number") : 1;
	save.day_time = map.getDayTime();
	save.bobert_day = this.get_u16("bobert_day");
	save.tech_data = SerializeTechTree();
	save.map_seed = this.get_s32("map_seed");

	// collect date & time saved
	save.date_saved = Time_Local();

	save.Write(config);

	config.saveFile(Save::SaveFileName + save_slot);

	QuerySave(save_slot);

	blobHandlers.deleteAll();
}

void QuerySave(const string&in save_slot)
{
	//add the save slot to our complete saves list

	ConfigFile saves = ConfigFile();
	if (!saves.loadFile("../Cache/" + Save::AllSavesFileName))
	{
		saves.saveFile(Save::AllSavesFileName);
	}

	const string all_saves = saves.read_string("all_saves", "");
	const string[]@ tokens = all_saves.split(" ");
	if (tokens.find(save_slot) == -1)
	{
		saves.add_string("all_saves", all_saves + " " + save_slot);
		saves.saveFile(Save::AllSavesFileName);
	}
}

/*
 Loading is divided into two parts.
 LoadSavedMap: called before rules scripts are initialized
 LoadSavedRules: called after rules scripts are initialized- for the purpose of overwriting variables
*/

bool LoadSavedMap(CRules@ this, CMap@ map)
{
	if (this.get_bool("loaded_saved_map")) return false;

	if (!isServer()) return true;

	const string save_slot = this.exists("mapsaver_save_slot") ? this.get_string("mapsaver_save_slot") : "AutoSave";

	ConfigFile config = ConfigFile();
	if (!config.loadFile("../Cache/" + Save::SaveFileName + save_slot)) return false;

	SaveFile@ save = SaveFile(config);

	const string[]@ dimensions = save.map_dimensions.split(";");
	if (dimensions.length < 2) { error("MapSaver: Failed to load saved map - Corrupt map dimensions"); return false; }

	const int width = parseInt(dimensions[0]);
	const int height = parseInt(dimensions[1]);

	map.CreateTileMap(width, height, 8.0f, "Sprites/world.png");

	InitializeBlobHandlers();

	LoadTiles(map, save.map_data);
	LoadWater(map, save.water_data);

	CBlob@[] loaded_blobs;
	LoadBlobs(map, save.blob_data, @loaded_blobs);
	LoadInventories(map, save.inventory_data, @loaded_blobs);
	LoadAttachments(map, save.attachment_data, @loaded_blobs);
	LoadDamageOwnerPlayers(save.owner_data, @loaded_blobs);
	LoadEquipment(map, save.equipment_data, @loaded_blobs);
	LoadTasks(map, save.task_data, @loaded_blobs);

	QuerySave(save_slot);

	blobHandlers.deleteAll();

	return true;
}

bool LoadSavedRules(CRules@ this, CMap@ map)
{
	if (this.get_bool("loaded_saved_map")) return false;

	if (!isServer()) return true;

	const string save_slot = this.exists("mapsaver_save_slot") ? this.get_string("mapsaver_save_slot") : "AutoSave";

	ConfigFile config = ConfigFile();
	if (!config.loadFile("../Cache/" + Save::SaveFileName + save_slot)) return false;

	SaveFile@ save = SaveFile(config);

	//dirt data has to be loaded late because of an engine issue..
	LoadDirt(map, save.dirt_data);

	LoadTechTree(this, save.tech_data);

	this.set_u16("day_number", save.day_number);
	this.Sync("day_number", true);

	this.set_u16("bobert_day", save.bobert_day);
	this.Sync("bobert_day", true);

	map.SetDayTime(save.day_time);
	this.set_u16("last_day_hour", Maths::Roundf(save.day_time*10));

	this.set_s32("map_seed", save.map_seed);
	this.Sync("map_seed", true);

	this.set_string("map_name", save.map_seed+"");
	this.Sync("map_name", true);

	this.set_bool("loaded_saved_map", true);

	return true;
}

void LoadTiles(CMap@ map, const string&in map_data)
{
	const string[]@ tiles = map_data.split(";");
	u32 current_index = 0;
	for (int i = 0; i < tiles.length - 1; i++)
	{
		string[]@ data = tiles[i].split(" ");
		if (data.length != 2) { error("MapSaver: Failed tile indices"); continue; }

		const int tile_type = parseInt(data[0]);
		const int tile_count = parseInt(data[1]);

		for (int j = 0; j < tile_count; j++)
		{
			map.SetTile(current_index++, tile_type);
		}
	}
}

void LoadDirt(CMap@ map, const string&in map_data)
{
	const string[]@ tiles = map_data.split(";");
	u32 current_index = 0;
	for (int i = 0; i < tiles.length - 1; i++)
	{
		string[]@ data = tiles[i].split(" ");
		if (data.length != 2) { error("MapSaver: Failed dirt indices"); continue; }

		const bool is_dirt = parseBool(data[0]);
		const int tile_count = parseInt(data[1]);

		for (int j = 0; j < tile_count; j++)
		{
			if (is_dirt)
			{
				map.RemoveTileFlag(current_index, Tile::LIGHT_SOURCE);
				map.SetTileDirt(current_index, 80);
			}
			current_index++;
		}
	}
}

void LoadWater(CMap@ map, const string&in map_data)
{
	const string[]@ tiles = map_data.split(";");
	u32 current_index = 0;
	for (int i = 0; i < tiles.length - 1; i++)
	{
		string[]@ data = tiles[i].split(" ");
		if (data.length != 2) { error("MapSaver: Failed water indices"); continue; }

		const bool has_water = parseBool(data[0]);
		const int tile_count = parseInt(data[1]);

		for (int j = 0; j < tile_count; j++)
		{
			map.server_setFloodWaterOffset(current_index++, has_water);
		}
	}
}

void LoadBlobs(CMap@ map, const string&in blob_data, CBlob@[]@ loaded_blobs)
{
	// each blob is separated by 2x semicolon
	const string[]@ blobs = blob_data.split(";;");
	for (int i = 0; i < blobs.length; i++)
	{
		if (blobs[i].isEmpty()) continue;

		string[]@ data = blobs[i].split(";");
		if (data.length < 3) { error("MapSaver: Failed indexing for blob data"); continue; }

		const string name = data[0];
		const Vec2f pos(parseFloat(data[1]), parseFloat(data[2]));
		BlobDataHandler@ handler = getBlobHandler(name);

		CBlob@ blob = handler.CreateBlob(name, pos, data);
		loaded_blobs.push_back(blob);

		if (blob is null) { error("MapSaver: Failed to load blob '"+name+"'"); continue; }

		handler.LoadBlobData(blob, data);
	}
}

void LoadInventories(CMap@ map, const string&in inventory_data, CBlob@[]@ loaded_blobs)
{
	const string[]@ pairs = inventory_data.split(";");
	for (int i = 0; i < pairs.length - 1; i++)
	{
		const string[]@ indices = pairs[i].split(" ");
		if (indices.length != 2) { error("MapSaver: Failed inventory indices"); continue; }
		
		const int blob_index = parseInt(indices[0]);
		const int parent_index = parseInt(indices[1]);
		if (blob_index >= loaded_blobs.length || parent_index >= loaded_blobs.length) { error("MapSaver: Failed inventory indices [out of bounds]"); continue; }

		CBlob@ blob = loaded_blobs[blob_index];
		CBlob@ parent = loaded_blobs[parent_index];
		if (blob is null || parent is null) continue;

		parent.server_PutInInventory(blob);
	}
}

void LoadAttachments(CMap@ map, const string&in attachment_data, CBlob@[]@ loaded_blobs)
{
	const string[]@ pairs = attachment_data.split(";");
	for (int i = 0; i < pairs.length - 1; i++)
	{
		const string[]@ indices = pairs[i].split(" ");
		if (indices.length != 3) { error("MapSaver: Failed attachment indices"); continue; }

		const int blob_index = parseInt(indices[0]);
		const int parent_index = parseInt(indices[1]);
		if (blob_index >= loaded_blobs.length || parent_index >= loaded_blobs.length) { error("MapSaver: Failed attachment indices [out of bounds]"); continue; }

		CBlob@ blob = loaded_blobs[blob_index];
		CBlob@ parent = loaded_blobs[parent_index];
		if (blob is null || parent is null) continue;

		const int ap_index = parseInt(indices[2]);
		blob.server_AttachTo(parent, ap_index);
	}
}

void LoadDamageOwnerPlayers(const string&in owner_data, CBlob@[]@ loaded_blobs)
{
	const string[]@ players = owner_data.split("}");
	for (int p = 0; p < players.length - 1; p++)
	{
		const string[]@ owner_compartments = players[p].split("{");
		if (owner_compartments.length != 2) { error("MapSaver: Failed owner compartments"); continue; }

		const string player_name = owner_compartments[0];
		CPlayer@ player = getPlayerByUsername(player_name); 

		const string[]@ blob_indexes = owner_compartments[1].split(";");
		for (int i = 0; i < blob_indexes.length - 1; i++)
		{
			const int blob_index = parseInt(blob_indexes[i]);
			if (blob_index >= loaded_blobs.length) { error("MapSaver: Failed owner [out of bounds]"); continue; }

			CBlob@ blob = loaded_blobs[blob_index];
			if (blob is null) continue;

			if (player !is null)
			{
				blob.SetDamageOwnerPlayer(player);
			}
			else
			{
				blob.set_string("damage_owner", player_name);
			}
		}
	}
}

void LoadEquipment(CMap@ map, const string&in equipment_data, CBlob@[]@ loaded_blobs)
{
	const string[]@ pairs = equipment_data.split(";");
	for (int i = 0; i < pairs.length - 1; i++)
	{
		const string[]@ indices = pairs[i].split(" ");
		if (indices.length != 3) { error("MapSaver: Failed equipment indices"); continue; }

		const int equipper_index = parseInt(indices[0]);
		const int equippedblob_index = parseInt(indices[1]);
		if (equipper_index >= loaded_blobs.length || equippedblob_index >= loaded_blobs.length) { error("MapSaver: Failed equipment indices [out of bounds]"); continue; }

		CBlob@ equipper = loaded_blobs[equipper_index];
		CBlob@ equippedblob = loaded_blobs[equippedblob_index];
		if (equipper is null || equippedblob is null) continue;

		u16[]@ ids;
		if (!equipper.get("equipment_ids", @ids)) continue;

		const int equipment_index = parseInt(indices[2]);
		ids[equipment_index] = equippedblob.getNetworkID();

		EquipBlob(equipper, equippedblob);
	}
}

void LoadTasks(CMap@ map, const string&in task_data, CBlob@[]@ loaded_blobs)
{
	if (task_data.isEmpty()) return;

	SetupTasksArray();

	const string[]@ managers = task_data.split("}");
	for (int m = 0; m < managers.length - 1; m++)
	{
		const string[]@ manager_compartments = managers[m].split("{");
		if (manager_compartments.length != 2) { error("MapSaver: Failed manager compartments"); continue; }

		const string[]@ manager_info = manager_compartments[0].split(";");
		if (manager_info.length < 2) { error("MapSaver: Failed manager info!"); continue; }

		const string[]@ manager_tasks = manager_compartments[1].split("|");

		const int blob_index = parseInt(manager_info[0]);
		if (blob_index >= loaded_blobs.length) { error("MapSaver: Failed task blob [out of bounds]"); continue; }

		CBlob@ blob = loaded_blobs[blob_index];
		if (blob is null) continue;

		TaskManager@ manager = getTaskManager(blob);
		if (manager is null) continue;

		manager.index = parseInt(manager_info[1]);

		manager.tasks.clear();

		for (int i = 0; i < manager_tasks.length; i++)
		{
			const string[]@ data = manager_tasks[i].split(";");

			const int type = parseInt(data[0]);
			BrainTask@ task = all_tasks[type].Copy(blob);
			task.LoadFromString(data, @loaded_blobs);
			manager.tasks.push_back(task);
		}
	}

	all_tasks.clear();
}

void LoadTechTree(CRules@ this, const string&in tech_data)
{
	const string[]@ indices = tech_data.split(";");

	onTechnologyRulesHandle@ onTechnologyRules;
	this.get("onTechnology handle", @onTechnologyRules);

	Technology@[]@ techTree = getTechTree();
	int data_index = 0;
	for (u8 i = 0; i < techTree.length; i++)
	{
		Technology@ tech = techTree[i];
		if (tech is null) continue;

		if (data_index + 4 >= indices.length) { error("MapSaver: Failed to load technology ["+i+"] - Legacy save file?"); break; }

		tech.time = parseInt(indices[data_index++]);
		tech.available = parseBool(indices[data_index++]);
		tech.paused = parseBool(indices[data_index++]);
		tech.completed = parseBool(indices[data_index++]);

		if (onTechnologyRules !is null)
		{
			onTechnologyRules(this, tech.index);
		}
	}

	if (!isClient() && this.exists("map_name")) // avoid cmd issues at first map load
	{
		CBitStream stream;
		SerializeTechTree(this, stream);
		this.SendCommand(this.getCommandID("client_synchronize_technology"), stream);
	}
}
