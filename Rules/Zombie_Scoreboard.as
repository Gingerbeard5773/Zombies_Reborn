//Zombie Fortress scoreboard

#define CLIENT_ONLY

#include "Zombie_Translation.as";

const f32 scoreboardMargin = 52.0f;
const f32 scrollSpeed = 4.0f;
const f32 maxMenuWidth = 380;

f32 scrollOffset = 0.0f;
bool mouseWasPressed2 = false;

u32 copy_time = 0;
string copy_name = "";
Vec2f copy_pos = Vec2f_zero;

f32 yFallDown = 0;
const f32 fallSpeed = 100.0f;

//returns the bottom
const f32 drawScoreboard(CPlayer@[]@ players, Vec2f&in topleft, const u8&in teamNum, const f32&in screenMidX)
{
	CRules@ rules = getRules();
	CTeam@ team = rules.getTeam(teamNum);
	
	const u8 playersLength = players.length;
	if (playersLength <= 0 || team is null)
		return topleft.y;
	
	const u16 zombies = rules.get_u16("undead count");

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
	GUI::DrawText(rules.getTeam(teamNum).getName(), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + playersLength), Vec2f(bottomright.x - 470, topleft.y), SColor(0xffffffff));
	GUI::DrawText(Translate::Zombies.replace("{AMOUNT}", zombies+""), Vec2f(bottomright.x - 270, topleft.y), SColor(0xffffffff));

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
					copy_time = getGameTime();
					copy_name = p.getUsername();
					copy_pos = mousePos + Vec2f(0, -10);
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
	if ((copy_time + 64) > getGameTime())
	{
		drawFancyCopiedText();
	}

	return topleft.y;
}

void onTick(CRules@ this)
{
	if (!isPlayerListShowing())
	{
		yFallDown = f32(getScreenHeight()) * 0.35f;
	}
}

void onRenderScoreboard(CRules@ this)
{
	if (this.get_bool("show_gamehelp")) return;
	
	yFallDown = Maths::Max(0, yFallDown - getRenderApproximateCorrectionFactor()*fallSpeed);
	
	CPlayer@[] survivors;
	const u8 plyCount = getPlayersCount();
	for (u8 i = 0; i < plyCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		const u8 teamNum = player.getTeamNum();
		if (teamNum == 0)
		{
			survivors.push_back(player);
		}
	}

	//draw board

	const f32 screenMidX = getScreenWidth()/2;
	Vec2f topleft(Maths::Max(100, screenMidX-maxMenuWidth), 150 - yFallDown);
	drawServerInfo(this, screenMidX, 40 - yFallDown);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//draw the scoreboard
	
	topleft.y = drawScoreboard(survivors, topleft, 0, screenMidX);
	topleft.y += 45;
	
	drawManualPointer(screenMidX, topleft.y);

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

void drawFancyCopiedText()
{
	const u32 time_left = getGameTime() - copy_time;
	const string text = "Username copied: " + copy_name;
	const Vec2f pos = copy_pos - Vec2f(0, time_left);
	const int col = (255 - time_left * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - time_left * 4), col, col, col));
}

void drawServerInfo(CRules@ this, const f32&in x, const f32&in y)
{
	GUI::SetFont("menu");

	Vec2f pos(x, y);
	f32 width = 200;

	const string info = getTranslatedString(this.gamemode_name) + ": " + getTranslatedString(this.gamemode_info);
	const string mapName = getTranslatedString("Map name : ") + this.get_string("map_name");
	const string dayCount = Translate::DayNum.replace("{DAYS}", this.get_u16("day_number")+"");
	
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	GUI::GetTextDimensions(mapName, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	pos.x -= width / 2;
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 80;

	Vec2f mid(x, y);

	GUI::DrawPane(pos, bot, SColor(0xffcccccc));
	
	mid.y += 15;
	GUI::DrawTextCentered(info, mid, color_white);
	mid.y += 15;
	GUI::DrawTextCentered(mapName, mid, color_white);
	mid.y += 25;
	GUI::DrawTextCentered(dayCount, mid, color_white);
}

void drawManualPointer(const f32&in x, const f32&in y)
{
	const string openHelp = Translate::Manual.replace("{KEY}", "["+getControls().getActionKeyKeyName(AK_MENU)+"]");
	
	Vec2f dim;
	GUI::GetTextDimensions(openHelp, dim);
	
	Vec2f pos(x, y);
	const f32 width = dim.x + 15;
	pos.x -= width / 2;
	
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 25;
	
	GUI::DrawPane(pos, bot, SColor(0xffcccccc));
	GUI::DrawTextCentered(openHelp, Vec2f(x, y+12), color_white);
}
