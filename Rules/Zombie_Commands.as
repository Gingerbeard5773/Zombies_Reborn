// Zombie Fortress chat commands

#include "Zombie_SoftBansCommon.as";
#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_WarnsCommon.as";

void printcommandslist()
{
	print("");
	print("     --- ZOMBIE FORTRESS COMMANDS --- ",                                              color_white);
	print(" !time [day time] : set the time of day",                                             color_white);
	print(" !dayspeed [minutes] : set the speed of the day",                                     color_white);
	print(" !day [day number] : set the day",                                                    color_white);
	print(" !dayreset : sets the day based off game time",                                       color_white);
	print(" !class [name] : set your character's blob",                                          color_white);
	print(" !cursor [blobname] [amount] : spawn a blob at your cursor",                          color_white);
	print(" !respawn [username] : respawn a player",                                             color_white);
	print(" !softban [username / IP] [minutes / -1 for permanent] [reason] : soft ban a player", color_white);
	print(" !carnage : kill all zombies on the map",                                             color_white);
	print(" !spawnrates [days to print] [player number] : prints out a prediction of the rates", color_white);
	print(" !difficulty [difficulty] : sets the game difficulty",                                color_white);
	print(" !loadgen [seed] : load a procedurally generated map using a seed",                   color_white);
	print(" !seed : get the map seed",                                                           color_white);
	print(" !warn : [player] [duration / in days, 0 for permanent] [reason] : warn a player",    color_white);
	print(" !technology : unlock all technologies",                                              color_white);
	print(" !debugprop [hash] : finds a string that pairs with the inputted hash",               color_white);
	print("");
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod() || player.getUsername() == "MrHobo")
	{
		if (text_in.substr(0,1) == "!")
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				CBlob@ pBlob = player.getBlob();
				if (pBlob !is null)
				{
					if (tokens[0] == "!class") //become any blob of your choice
					{
						CBlob@ b = server_CreateBlob(tokens[1], pBlob.getTeamNum(), pBlob.getPosition());
						if (b !is null)
						{
							b.server_SetPlayer(player);
							pBlob.server_Die();
						}
						return false;
					}
				}

				if (tokens[0] == "!cursor") //spawn a blob at cursor position
				{
					CBlob@ pBlob = player.getBlob();
					Vec2f pos = pBlob !is null ? pBlob.getAimPos() : getControls().getMouseWorldPos();
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
				else if (tokens[0] == "!time") //set the day time
				{
					getMap().SetDayTime(parseFloat(tokens[1]));
				}
				else if (tokens[0] == "!dayspeed") //set the speed of the day
				{
					this.daycycle_speed = parseInt(tokens[1]);
				}
				else if (tokens[0] == "!day") //set the day
				{
					this.set_u16("day_number", parseInt(tokens[1]));
					this.Sync("day_number", true);
					//getMap().SetDayTime(this.daycycle_start);
				}
				else if (tokens[0] == "!softban") //soft ban a player
				{
					if (tokens.length < 3)
					{
						warn("!softban:: missing perameters");
						return false;
					}

					SoftBan(tokens[1], tokens.length > 3 ? tokens[3] : "", parseInt(tokens[2])*60);
					CPlayer@ bannedPlayer = getPlayerByUsername(tokens[1]);
					if (bannedPlayer !is null)
					{
						SetUndead(this, bannedPlayer);
					}
				}
			}
			else
			{
				if (tokens[0] == "!list") //print of a list of all these commands
				{
					printcommandslist();
					return false;
				}
				else if (tokens[0] == "!carnage") //kill all undeads
				{
					CBlob@[] blobs;
					getBlobsByTag("undead", @blobs);
					const u16 blobsLength = blobs.length;
					for (u16 i = 0; i < blobsLength; ++i)
					{
						CBlob@ blob = blobs[i];
						blob.server_Die();
					}
				}
				else if (tokens[0] == "!dayreset") //sets the day based off the current gametime
				{
					const u32 day_cycle = this.daycycle_speed * 60;
					const u16 dayNumber = (getGameTime() / getTicksASecond() / day_cycle) + 1;

					this.set_u16("day_number", dayNumber);
					this.Sync("day_number", true);
				}
				else if (tokens[0] == "!seed")
				{
					const int map_seed = getMap().get_s32("map seed");
					const string message = "MAP SEED : "+map_seed;
					print(message);
					server_SendGlobalMessage(this, message, 10);

					if (isClient()) //localhost only atm
						CopyToClipboard(map_seed+"");

					return false;
				}
			}

			if (tokens[0] == "!respawn") //respawn player
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
			else if (tokens[0] == "!debugprop")
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
				
				for (u8 i = 0; i < props.length; ++i)
				{
					const string prop = props[i];
					if (prop.getHash() == hash)
						print(prop+" : "+prop.getHash());
				}
			}
		}
	}

	// check if the player can ban another player
	if (canPlayerBan(player))
	{
		string[]@ tokens = text_in.split(" ");

		if (tokens[0] == "!warn")
		{
			if (tokens.length > 1)
			{
				string targetPlayer = tokens[1];
				string reason = tokens.length > 3 ? tokens[3] : "";
				// add the reason into a string
				for(int i = 4; i < tokens.length; i++)
				{
					reason += " " + tokens[i];
				}

				s32 duration = tokens.length > 2 ? parseInt(tokens[2]) : warnDuration;
				if (duration < 0) duration = 0;
				WarnPlayer(player, targetPlayer, duration, reason);
			}
		}
	}

	return true;
}
