//Zombie Fortress scoreboard

#define CLIENT_ONLY

#include "Zombie_Translation.as";

const f32 scoreboardMargin = 52.0f;
const f32 scrollSpeed = 4.0f;
const f32 maxMenuWidth = 380;
const f32 screenMidX = getScreenWidth()/2;

f32 scrollOffset = 0.0f;
bool mouseWasPressed2 = false;
CPlayer@ hoveredPlayer;

//returns the bottom
const f32 drawScoreboard(CPlayer@[] players, Vec2f topleft, const u8 teamNum)
{
	CRules@ rules = getRules();
	CTeam@ team = rules.getTeam(teamNum);
	
	const u8 playersLength = players.length;
	if (playersLength <= 0 || team is null)
		return topleft.y;

	const f32 lineheight = 16;
	const f32 padheight = 2;
	const f32 stepheight = lineheight + padheight;
	Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + (playersLength + 5.5) * stepheight);
	GUI::DrawPane(topleft, bottomright, team.color);

	//offset border
	topleft.x += stepheight;
	bottomright.x -= stepheight;
	topleft.y += stepheight;

	GUI::SetFont("menu");

	//draw team info
	GUI::DrawText(teams[teamNum], Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + playersLength), Vec2f(bottomright.x - 470, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 2;
	
	//draw player table header
	
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Username"), Vec2f(bottomright.x - 440, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 270, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 200, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 0.5f;

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

	//draw players
	for (u8 i = 0; i < playersLength; i++)
	{
		CPlayer@ p = players[i];

		topleft.y += stepheight;
		bottomright.y = topleft.y + lineheight;

		const bool playerHover = mousePos.y > topleft.y && mousePos.y < topleft.y + 15;
		if (playerHover)
		{
			if (controls.mousePressed2 && !mouseWasPressed2)
			{
				// reason for this is because this is called multiple per click (since its onRender, and clicking is updated per tick)
				// we don't want to spam anybody using a clipboard history program
				if (getFromClipboard() != p.getUsername())
				{
					CopyToClipboard(p.getUsername());
					rules.set_u16("client_copy_time", getGameTime());
					rules.set_string("client_copy_name", p.getUsername());
					rules.set_Vec2f("client_copy_pos", mousePos + Vec2f(0, -10));
				}
			}
		}

		Vec2f lineoffset = Vec2f(0, -2);

		const bool deadPlayer = p.getBlob() is null || p.getBlob().hasTag("dead") || p.getBlob().hasTag("undead");
		const u32 underlinecolor = 0xff404040;
		u32 playercolour = deadPlayer ? 0xff505050 : 0xff808080;
		if (playerHover)
		{
			playercolour = 0xffcccccc;
			@hoveredPlayer = p;
		}

		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, SColor(underlinecolor));
		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));

		const string tex = p.getScoreboardTexture();

		if (p.isMyPlayer() && tex.isEmpty())
			GUI::DrawIcon("ScoreboardIcons", 2, Vec2f(16,16), topleft, 0.5f, p.getTeamNum());
		else if (!tex.isEmpty())
			GUI::DrawIcon(tex, p.getScoreboardFrame(), p.getScoreboardFrameSize(), topleft, 0.5f, p.getTeamNum());

		const string username = p.getUsername();
		const string playername = p.getCharacterName();
		const string clantag = p.getClantag();

		//have to calc this from ticks
		const s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);

		//how much room to leave for names and clantags
		const f32 name_buffer = 26.0f;

		//render the player + stats
		const SColor namecolour = deadPlayer ? 0xffC65B5B : 0xffFFFFFF;

		//right align clantag
		if (!clantag.isEmpty())
		{
			Vec2f clantag_actualsize(0, 0);
			GUI::GetTextDimensions(clantag, clantag_actualsize);
			
			GUI::DrawText(clantag, topleft + Vec2f(name_buffer, 0), SColor(0xff888888));
			//draw name alongside
			GUI::DrawText(playername, topleft + Vec2f(name_buffer + clantag_actualsize.x + 8, 0), namecolour);
		}
		else
		{
			//draw name alone
			GUI::DrawText(playername, topleft + Vec2f(name_buffer, 0), namecolour);
		}

		GUI::DrawText("" + username, Vec2f(bottomright.x - 440, topleft.y), namecolour);
		GUI::DrawText("" + p.getKills(), Vec2f(bottomright.x - 270, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getDeaths(), Vec2f(bottomright.x - 200, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));
	}

	// username copied text, goes at bottom to overlay above everything else
	u32 durationLeft = rules.get_u16("client_copy_time");

	if ((durationLeft + 64) > getGameTime())
	{
		durationLeft = getGameTime() - durationLeft;
		drawFancyCopiedText(rules.get_string("client_copy_name"), rules.get_Vec2f("client_copy_pos"), durationLeft);
	}

	return topleft.y;
}

void onRenderScoreboard(CRules@ this)
{
	if (this.get_bool("show_gamehelp")) return;
	
	const u8 playingTeamsCount = 1; //change this depending on how many teams in the gamemode, this.getTeamsNum() causes errors
	CPlayer@[][] teamsPlayers(playingTeamsCount); //holds all teams and their players
	CPlayer@[] spectators;
	const u8 plyCount = getPlayersCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}

		const u8 teamNum = p.getTeamNum();
		if (teamNum < playingTeamsCount)
		{
			teamsPlayers[teamNum].push_back(p);
		}
	}

	//draw board

	@hoveredPlayer = null;

	Vec2f topleft(Maths::Max(100, screenMidX-maxMenuWidth), 150);
	drawServerInfo(this, 40);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//draw the scoreboards
	
	const u8 teamsPlyLength = teamsPlayers.length;
	for (u8 i = 0; i < teamsPlyLength; i++)
	{
		if (teamsPlayers[i].length > 0)
		{
			topleft.y = drawScoreboard(teamsPlayers[i], topleft, i);
			topleft.y += 45;
		}
	}

	const u8 spectatorsLength = spectators.length;
	if (spectatorsLength > 0)
	{
		//draw spectators
		const f32 stepheight = 16;
		Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + stepheight * 2);
		const f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		const string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u8 i = 0; i < spectatorsLength; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectatorsLength - 1)
					name += ",";
				GUI::GetTextDimensions(name, textdim);
				GUI::DrawText(name, Vec2f(specx, specy), color_white);
				specx += textdim.x + 10;
			}
			else
			{
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), SColor(0xffaaaaaa));
				break;
			}
		}

		topleft.y += 52;
	}
	
	drawManualPointer(topleft.y);

	const float scoreboardHeight = topleft.y + scrollOffset;
	const float screenHeight = getScreenHeight();
	CControls@ controls = getControls();

	if (scoreboardHeight > screenHeight)
	{
		Vec2f mousePos = controls.getMouseScreenPos();

		const f32 fullOffset = (scoreboardHeight + scoreboardMargin) - screenHeight;

		if (scrollOffset < fullOffset && mousePos.y > screenHeight*0.83f)
		{
			scrollOffset += scrollSpeed;
		}
		else if (scrollOffset > 0.0f && mousePos.y < screenHeight*0.16f)
		{
			scrollOffset -= scrollSpeed;
		}

		scrollOffset = Maths::Clamp(scrollOffset, 0.0f, fullOffset);
	}

	mouseWasPressed2 = controls.mousePressed2; 
}

void drawFancyCopiedText(string username, Vec2f mousePos, uint duration)
{
	const string text = "Username copied: " + username;
	const Vec2f pos = mousePos - Vec2f(0, duration);
	const int col = (255 - duration * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - duration * 4), col, col, col));
}

void drawServerInfo(CRules@ this, const f32 y)
{
	GUI::SetFont("menu");

	Vec2f pos(screenMidX, y);
	f32 width = 200;

	const string info = getTranslatedString(this.gamemode_name) + ": " + getTranslatedString(this.gamemode_info);
	const string mapName = getTranslatedString("Map name : ") + this.get_string("map_name");
	const string dayCount = ZombieDesc::day+": " + this.get_u8("day_number");
	
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	GUI::GetTextDimensions(mapName, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	pos.x -= width / 2;
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 80;

	Vec2f mid(screenMidX, y);

	GUI::DrawPane(pos, bot, SColor(0xffcccccc));
	
	mid.y += 15;
	GUI::DrawTextCentered(info, mid, color_white);
	mid.y += 15;
	GUI::DrawTextCentered(mapName, mid, color_white);
	mid.y += 25;
	GUI::DrawTextCentered(dayCount, mid, color_white);
}

void drawManualPointer(const f32 y)
{
	const string openHelp = ZombieDesc::open_manual.replace("{KEY}", "["+getControls().getActionKeyKeyName(AK_MENU)+"]");
	
	Vec2f dim;
	GUI::GetTextDimensions(openHelp, dim);
	
	Vec2f pos(screenMidX, y);
	const f32 width = dim.x + 15;
	pos.x -= width / 2;
	
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 25;
	
	GUI::DrawPane(pos, bot, SColor(0xffcccccc));
	GUI::DrawTextCentered(openHelp, Vec2f(screenMidX, y+12), color_white);
}
