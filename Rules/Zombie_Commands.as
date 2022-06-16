// Zombie Fortress chat commands

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
		}
	}
	return true;
}
