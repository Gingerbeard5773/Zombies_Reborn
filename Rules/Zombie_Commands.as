// Zombie Fortress chat commands

#include "RespawnCommon.as";

const string commandslist()
{
	return
	"\n     --- ZOMBIE FORTRESS COMMANDS --- \n"+
	"\n !time [day time] : set the time of day"+
	"\n !dayspeed [minutes] : set the speed of the day"+
	"\n !class [name] : set your character's blob"+
	"\n !cursor [blobname] [amount] : spawn a blob at your cursor"+
	"\n !respawn [username] : respawn a player"+
	"\n !softban [username / IP] [minutes / -1 for permanent] [reason] : soft ban a player"+ 
	"\n !carnage : kill all zombies on the map"+
	"\n !undeadcount : print the amount of zombies on the map"+
	"\n !state : toggle warmup on or off\n";
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
					server_CreateBlob(tokens[1], -1, getControls().getMouseWorldPos());
					if (tokens.length > 2)
					{
						const u8 amount = parseInt(tokens[2])-1;
						for (u8 i = 0; i < amount; ++i)
						{
							server_CreateBlob(tokens[1], -1, getControls().getMouseWorldPos());
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
				else if (tokens[0] == "!softban") //soft ban a player
				{
					if (tokens.length < 3)
					{
						warn("!softban:: missing perameters");
						return false;
					}
					if (!this.hasCommandID("server_softban"))
					{
						warn("!softban:: CMD 'server_soft_ban' missing");
						return false;
					}
					
					CBitStream params;
					params.write_string(tokens[1]);
					params.write_string(tokens.length > 3 ? tokens[3] : "");
					params.write_s32(parseInt(tokens[2])*60);
					this.SendCommand(this.getCommandID("server_softban"), params, false);
				}
			}
			else
			{
				if (tokens[0] == "!list") //print of a list of all these commands
				{
					print(commandslist(), color_white);
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
				else if (tokens[0] == "!undeadcount") //print the amount of undeads
				{
					CBlob@[] undeads;
					getBlobsByTag("undead", @undeads);
					print(undeads.length+" undeads found");
					return false;
				}
				else if (tokens[0] == "!state")
				{
					this.SetCurrentState(this.getCurrentState() == WARMUP ? GAME : WARMUP);
					this.SetGlobalMessage(this.getCurrentState() == GAME ? "Gamestate: GAME" : "Gamestate: WARMUP");
					this.set_u8("message_timer", 5);
					return false;
				}
			}
			
			if (tokens[0] == "!respawn") //respawn player
			{
				Respawn[]@ respawns;
				if (!this.get("respawns", @respawns))
				{
					warn("!respawn:: Respawns not found!");
					return false;
				}
				
				const string ply_name = tokens.length > 1 ? tokens[1] : player.getUsername();
				for (u8 i = 0; i < respawns.length; i++)
				{
					Respawn@ r = respawns[i];
					if (r.username != ply_name) continue;
					
					r.timeStarted = 0;
				}
			}
		}
	}
	return true;
}
