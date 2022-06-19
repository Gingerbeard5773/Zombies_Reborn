// Zombie Fortress chat commands

const string commandslist()
{
	return
	"\n     --- ZOMBIE FORTRESS COMMANDS --- \n"+
	"\n !time [day time] : set the time of day"+
	"\n !dayspeed [minutes] : set the speed of the day"+
	"\n !class [name] : set your character's blob"+
	"\n !cursor [blobname] [amount] : spawn a blob at your cursor"+
	"\n !undeadcount : print the amount of zombies on the map\n";
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null) return true;

	//for testing
	if (sv_test || player.isMod())
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
			}
			else
			{
				if (tokens[0] == "!list") //print of a list of all these commands
				{
					print(commandslist(), color_white);
					return false;
				}
				else if (tokens[0] == "!undeadcount") //print the amount of undeads
				{
					CBlob@[] undeads;
					getBlobsByTag("undead", @undeads);
					print(undeads.length+" undeads found");
					return false;
				}
			}
		}
	}
	return true;
}
