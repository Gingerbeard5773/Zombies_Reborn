// Zombie Fortress chat commands

#include "Zombie_SoftBansCommon.as";
#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_WarnsCommon.as";
#include "MapSaver.as";

//Use ' !list ' in game to view the commands list.

string CommandsList()
{
	return
	"\n     --- ZOMBIE FORTRESS COMMANDS --- \n" +
	"!time [day time] : set the time of day\n" +
	"!dayspeed [minutes] : set the speed of the day\n" +
	"!day [day number] : set the day\n" +
	"!class [name] : set your character's blob\n" +
	"!cursor [blobname] [amount] : spawn a blob at your cursor\n" +
	"!respawn [username] : respawn a player\n" +
	"!softban [username / IP] [minutes / -1 for permanent] [reason] : soft ban a player\n" +
	"!carnage : kill all zombies on the map\n" +
	"!spawnrates [days to print] [player number] : prints out a prediction of the rates\n" +
	"!difficulty [difficulty] : sets the game difficulty\n" +
	"!loadgen [seed] : load a procedurally generated map using a seed\n" +
	"!seed : get the map seed\n" +
	"!warn [player] [duration / in days, 0 for permanent] [reason] : warn a player\n" +
	"!technology : unlock all technologies\n" +
	"!debugprop [hash] : finds a string that pairs with the hash input\n" +
	"!structure [index] : loads a structure from cfg. no index = random\n" +
	"!savestructure : saves a structure at the player's position\n" +
	"!savemap [save name] : saves the current map to your save slot\n" +
	"!loadsave [save name] : loads a saved map from config";
}

const string[] isCool = { "MrHobo" };

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	if (text_in.substr(0, 1) == "!")
	{
		CBlob@ blob = player.getBlob();

		string[]@ tokens = text_in.split(" ");

		CSecurity@ sec = getSecurity();
		const string role = sec.getPlayerSeclev(player).getName();
		const bool isLocalhost = isServer() && isClient();
		const bool isDev = isCool.find(player.getUsername()) != -1 || isLocalhost || player.isMod() || player.isRCON() || role == "Super Admin";
		const bool isMod = isDev || role == "Admin" || sec.checkAccess_Command(player, "ban");

		if (!PlayerCommands(this, tokens, player, blob))
			return false;

		if (isMod && !ModeratorCommands(this, tokens, player, blob))
			return false;

		if (isDev && !DeveloperCommands(this, tokens, player, blob))
			return false;
			
		if (isMod)
			return true;
	}

	return !isSoftBanned(player);
}

bool PlayerCommands(CRules@ this, string[]@ tokens, CPlayer@ player, CBlob@ blob)
{
	//none atm
	return true;
}

bool ModeratorCommands(CRules@ this, string[]@ tokens, CPlayer@ player, CBlob@ blob)
{
	if (tokens[0] == "!softban")
	{
		if (tokens.length < 3)
		{
			server_SendGlobalMessage(this, "!softban [username / IP] [minutes / -1 for permanent] [reason]", 10, ConsoleColour::WARNING.color, player);
			return false;
		}

		SoftBan(tokens[1], tokens.length > 3 ? tokens[3] : "", parseInt(tokens[2])*60);
		CPlayer@ bannedPlayer = getPlayerByUsername(tokens[1]);
		if (bannedPlayer !is null)
		{
			SetUndead(this, bannedPlayer);
		}
	}
	else if (tokens[0] == "!warn")
	{
		if (tokens.length < 2)
		{
			server_SendGlobalMessage(this, "!warn [player] [duration / in days, 0 for permanent] [reason]", 10, ConsoleColour::WARNING.color, player);
			return false;
		}

		const string targetPlayer = tokens[1];
		string reason = tokens.length > 3 ? tokens[3] : "";
		// add the reason into a string
		for (int i = 4; i < tokens.length; i++)
		{
			reason += " " + tokens[i];
		}

		s32 duration = tokens.length > 2 ? parseInt(tokens[2]) : warnDuration;
		if (duration < 0) duration = 0;
		WarnPlayer(player, targetPlayer, duration, reason);
	}
	else if (tokens[0] == "!list")
	{
		server_SendGlobalMessage(this, CommandsList(), 15, color_white.color, player);
		const string[]@ commands = CommandsList().split("\n");

		// Print each individual line
		for (uint i = 0; i < commands.length(); i++)
		{
			print(commands[i]);
		}
		return false;
	}

	return true;
}

bool DeveloperCommands(CRules@ this, string[]@ tokens, CPlayer@ player, CBlob@ blob)
{
	if (tokens[0] == "!class" && tokens.length > 1)
	{
		if (blob is null) return false;

		CBlob@ b = server_CreateBlob(tokens[1], blob.getTeamNum(), blob.getPosition());
		if (b !is null)
		{
			b.server_SetPlayer(player);
			blob.server_Die();
		}
		return false;
	}
	else if (tokens[0] == "!cursor" && tokens.length > 1)
	{
		Vec2f pos = blob !is null ? blob.getAimPos() : getControls().getMouseWorldPos();
		server_CreateBlob(tokens[1], -1, pos);
		if (tokens.length > 2)
		{
			const u8 amount = parseInt(tokens[2])-1;
			for (u8 i = 0; i < amount; ++i)
			{
				server_CreateBlob(tokens[1], -1, pos);
			}
		}
	}
	else if (tokens[0] == "!time" && tokens.length > 1)
	{
		getMap().SetDayTime(parseFloat(tokens[1]));
	}
	else if (tokens[0] == "!dayspeed" && tokens.length > 1)
	{
		this.daycycle_speed = parseInt(tokens[1]);
	}
	else if (tokens[0] == "!day" && tokens.length > 1)
	{
		this.set_u16("day_number", parseInt(tokens[1]));
		this.Sync("day_number", true);
	}
	else if (tokens[0] == "!carnage") //kill all undeads
	{
		CBlob@[] blobs;
		getBlobsByTag("undead", @blobs);
		for (u16 i = 0; i < blobs.length; ++i)
		{
			blobs[i].server_Die();
		}
	}
	else if (tokens[0] == "!seed")
	{
		const int map_seed = getMap().get_s32("map seed");
		const string message = "MAP SEED : "+map_seed;
		print(message);
		server_SendGlobalMessage(this, message, 10, color_white.color, player);

		if (isClient()) //localhost only atm
			CopyToClipboard(map_seed+"");

		return false;
	}
	else if (tokens[0] == "!respawn")
	{
		const string ply_name = tokens.length > 1 ? tokens[1] : player.getUsername();

		if (getPlayerByUsername(ply_name) !is null)
		{
			dictionary@ respawns;
			this.get("respawns", @respawns);

			respawns.set(ply_name, getGameTime());
		}
	}
	else if (tokens[0] == "!loadgen")
	{
		int map_seed = getMap().get_s32("map seed");
		if (tokens.length > 1)
		{
			map_seed = parseInt(tokens[1]); // direct seed input
			if (map_seed <= 0)
			{
				//otherwise make a seed from letters
				u32 hash = 5381;
				for (u32 i = 0; i < tokens[1].length(); i++)
				{
					hash = ((hash << 5) + hash) + tokens[1][i];
					hash &= 0x7FFFFFFF;
				}
				map_seed = hash;
			}
		}

		this.set_s32("new map seed", map_seed);
		LoadNextMap();
	}
	else if (tokens[0] == "!debugprop" && tokens.length > 1)
	{
		//yes LMAO.
		const string[] props =
		{
			"strategy", "spell countdown", "spell portal spawn", "spell num", "day_number",
			"day_record", "client respawn time", "map_name", "undead count", "popup state",
			"popout timer", "fuel_level", "buildblob", "has_arrow", "archerInfo", "equipment_ids",
			"blockCursor", "queued pickaxe", "moveVars", "hitdata", "onEquip handle",
			"onUnequip handle", "onHitOwner handle", "onTickSpriteEquipped handle",
			"onClientJoin handle", "onCycle handle", "onSwitch handle", "hover-poly",
			"emotes", "tileOffsets", "crate presets", "production", "crossbowInfo",
			"gunInfo", "onFire handle", "onReload handle", "harvest", "pull_items",
			"onAssignWorker handle", "onUnassignWorker handle", "assigned netids", "override head",
			"assigned netid", "factory_production_set", "layer setups", "onProduceItem handle",
			"Craft", "onTechnology handle", "power grid", "component", "VehicleInfo",
			"autograb blobs", "shop", "onShopMadeItem handle", "skelepede_segment_netids", "attackVars",
			"target netids", "respawns", "softban_spawn_queue", "Tech Tree", "has_arrow",
			"autopick time", "build page", "buildtile", "build page", "cant build time",
			"building space", "backpack position", "show build time", "warmup build delay",
			"build delay", "shieldDamage", "shieldDamageVel", "ShieldWorldPoint", "brain_obstruction_threshold",
			"brain_destination", "justgo", "head index", "head texture", "gui_HUD_slots_width", "equipment_icon",
			"gib health", "death time", "teleport pos", "release click", "can button tap", "inventory offset",
			"tap_time", "unpack time", "emote", "emotetime", "launch team", "blocks_pierced", "time_enter",
			"drill timer", "drill heat", "drill last active", "showHeatTo", "packed", "frame", "packed name",
			"unpack secs","boobytrap_cooldown_time", "required space", "factory netid", "equipper_id",
			"next_parachute", "custom_explosion_sound", "map_damage_radius", "map_damage_ratio", "map_damage_raycast",
			"custom_hitter", "explosive_teamkill", "map_bomberman_width", "eat_sound", "lantern lit",
			"arrow type", "angle", "lock", "arrow type", "stuck_arrow_index", "override fire pos",
			"bullet time", "pierced", "bullet damage", "scroll defname0", "seed_grow_blobname", "player_username",
			"end attack", "harvestWoodDoorCap", "harvestStoneDoorCap", "harvestPlatformCap", "required class",
			"pull_items_button_offset", "background tile", "owner id", "maximum_worker_count", "can produce",
			"production offset", "production sound", "mill power", "state", "facing", "oar offset",
			"last_drop", "hadattached", "time till departure", "move_direction", "bowid", "greg_next_grab",
			"brain_delay", "brain_player_target", "brain_destination", "skelepede_head_netid", "stun_time",
			"died", "coins on death", "auto_enrage_time", "explosive_radius", "attack distance", "new map seed",
			"colour", "version", "sleeper_name", "score_undead_killed_total", "researching",
			"buildermats_time", "archermats_time", "just hit dirt"
		};
		
		u32 hash = 0;
		if (tokens.length > 1)
		{
			hash = parseInt(tokens[1]);
		}
		
		for (u16 i = 0; i < props.length; ++i)
		{
			const string prop = props[i];
			if (prop.getHash() == hash)
				print(prop+" : "+prop.getHash());
		}
	}
	else if (tokens[0] == "!loadsave")
	{
		const string SaveSlot = tokens.length > 1 ? tokens[1] : "AutoSave"; 
		this.set_string("mapsaver_save_slot", SaveSlot);
		this.set_bool("loaded_saved_map", false);
		LoadNextMap();
		return false;
	}
	else if (tokens[0] == "!ripserver")
	{
		error("SERVER SHUT OFF by "+ player.getUsername());
		QuitGame();
		return false;
	}
	
	return true;
}

bool onClientProcessChat(CRules@ this, const string &in text_in, string &out text_out, CPlayer@ player)
{
	if (player.isMyPlayer() && text_in.substr(0, 1) == "!")
	{
		const string[]@ tokens = text_in.split(" ");
		if (tokens[0] == "!savemap")
		{
			const string SaveSlot = tokens.length > 1 ? tokens[1] : "AutoSave";
			const string message = "Map saved to your cache: "+SaveSlot;
			print(message, 0xff66C6FF);
			client_SendGlobalMessage(this, message, 5, 0xff66C6FF);
			SaveMap(this, getMap(), SaveSlot);
			return false;
		}
	}

	return true;
}
