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

bool mousePress = false;

//returns the bottom
const f32 drawScoreboard(CPlayer@[]@ players, Vec2f&in topleft, const u8&in teamNum, const f32&in screenMidX, const string&in teamName)
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

	//draw team info
	GUI::DrawText(teamName, Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
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
			if (controls.mousePressed1 && !mousePress)
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
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_MENU)))
	{
		show_gamehelp = !show_gamehelp;
	}

	if (!isPlayerListShowing())
	{
		yFallDown = f32(getScreenHeight()) * 0.35f;
	}
}

void onRenderScoreboard(CRules@ this)
{
	if (show_gamehelp) return;
	
	yFallDown = Maths::Max(0, yFallDown - getRenderApproximateCorrectionFactor()*fallSpeed);
	
	CPlayer@[] survivors;
	CPlayer@[] spectators;
	const u8 spectator_team = this.getSpectatorTeamNum();
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		const u8 teamNum = player.getTeamNum();
		if (teamNum == 0)
		{
			survivors.push_back(player);
		}
		else if (teamNum == spectator_team)
		{
			spectators.push_back(player);
		}
	}

	//draw board

	const f32 screenMidX = getScreenWidth()/2;
	Vec2f topleft(Maths::Max(100, screenMidX-maxMenuWidth), 150 - yFallDown);
	drawServerInfo(this, screenMidX, 40 - yFallDown);
	
	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();
	
	makeWebsiteLink(topleft + Vec2f(0, -70), "Discord", "https://discord.gg/V29BBeba3C", controls, mousePos);
	makeWebsiteLink(topleft + Vec2f(100, -70), "Github", "https://github.com/Gingerbeard5773/Zombies_Reborn", controls, mousePos);
	
	drawStagingPopup(topleft);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//draw the scoreboard
	GUI::SetFont("menu");

	topleft.y = drawScoreboard(survivors, topleft, 0, screenMidX, Translate::Survivors);
	topleft.y += 45;
	
	if (spectators.length > 0)
	{
		//draw spectators
		f32 stepheight = 16;
		Vec2f bottomright(Maths::Min(getScreenWidth() - 100, getScreenWidth()/2 + maxMenuWidth), topleft.y + stepheight * 2);
		f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectators.length - 1)
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
	}

	topleft.y += 52;
	
	drawManualPointer(screenMidX, topleft.y);

	const float scoreboardHeight = topleft.y + scrollOffset;
	const float screenHeight = getScreenHeight();

	if (scoreboardHeight > screenHeight)
	{
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

	mousePress = controls.mousePressed1; 
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

	const string info = Translate::ZF2;
	const string mapName = getTranslatedString("Map: {MAP}").replace("{MAP}", this.get_string("map_name"));
	const string dayRecord = Translate::Stat4.replace("{INPUT}", this.get_u16("day_record")+"");
	const string dayCount = Translate::DayNum.replace("{DAYS}", this.get_u16("day_number")+"");
	
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	GUI::GetTextDimensions(mapName, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	pos.x -= width / 2;
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 100;

	Vec2f mid(x, y);

	GUI::DrawPane(pos, bot, SColor(0xffcccccc));
	
	mid.y += 15;
	GUI::DrawTextCentered(info, mid, color_white);
	mid.y += 15;
	GUI::DrawTextCentered(mapName, mid, color_white);
	mid.y += 25;
	GUI::DrawTextCentered(dayRecord, mid, color_white);
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


///GAMEHELP

bool show_gamehelp = true;
u8 page = 0;
const u8 pages = 7;

const string[] page_tips =
{
	Translate::Tip0,
	Translate::Tip1,
	Translate::Tip2,
	Translate::Tip3,
	Translate::Tip4,
	Translate::Tip5,
	Translate::Tip6,
	Translate::Tip7
};

void onInit(CRules@ this)
{
	CFileImage@ image = CFileImage("HelpBackground.png");
	const Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());
	AddIconToken("$HELP$", "HelpBackground.png", imageSize, 0);
}

void onRender(CRules@ this)
{
	if (!show_gamehelp) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	Vec2f center = getDriver().getScreenCenterPos();

	//background
	Vec2f imageSize;
	GUI::GetIconDimensions("$HELP$", imageSize);
	Vec2f topLeft(center.x - imageSize.x, center.y - imageSize.y);
	GUI::DrawIconByName("$HELP$", topLeft);
	
	//pages
	managePages(imageSize, center);
	
	//clickable buttons
	CControls@ controls = getControls();
	const Vec2f mousePos = controls.getMouseScreenPos();
	makeExitButton(this, Vec2f(center.x + imageSize.x - 20, center.y - imageSize.y + 20), controls, mousePos);
	makePageChangeButton(Vec2f(center.x+22, center.y + imageSize.y + 30), controls, mousePos, true);
	makePageChangeButton(Vec2f(center.x-22, center.y + imageSize.y + 30), controls, mousePos, false);
	drawStagingPopup(topLeft);
	makeWebsiteLink(Vec2f(topLeft.x, center.y + imageSize.y + 10), "Discord", "https://discord.gg/V29BBeba3C", controls, mousePos);
	makeWebsiteLink(Vec2f(topLeft.x + 100, center.y + imageSize.y + 10), "Github", "https://github.com/Gingerbeard5773/Zombies_Reborn", controls, mousePos);
	
	//page num
	drawTextWithFont((page+1)+"/"+pages, center + imageSize - Vec2f(30, 25), "medium font");
	
	mousePress = controls.mousePressed1; 
}

void managePages(Vec2f&in imageSize, Vec2f&in center)
{
	switch(page)
	{
		case 0: drawPage(imageSize, center, Translate::ZF, Vec2f(center.x - imageSize.x, center.y - imageSize.y/2));
			break;
		//case 1: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x/2, center.y - imageSize.y/3), 1);
			//break;
		case 1: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3), 2);
			break;
		case 2: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3), 3);
			break;
		case 3: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3), 4);
			break;
		case 4: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 150, center.y - imageSize.y/3), 5);
			break;
		case 5: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 150, center.y - imageSize.y/3), 6);
			break;
		case 6: drawPage(imageSize, center, Translate::Tips, Vec2f(center.x - imageSize.x + 200, center.y - imageSize.y/3), 7);
			break;
	};
}

void drawPage(Vec2f&in imageSize, Vec2f&in center, const string&in header, Vec2f&in imagePos, const u8&in pageNum = 0)
{
	GUI::DrawIcon("Page"+(pageNum+1)+".png", imagePos);
	const bool isRussian = g_locale == "ru";
	drawTextWithFont(header, center - Vec2f(0, imageSize.y - 50), isRussian ? "vinque" : "big font");
	drawTextWithFont(page_tips[pageNum], center - Vec2f(0, imageSize.y - 140), isRussian ? "anticva" : "medium font");
}

void drawTextWithFont(const string&in text, const Vec2f&in pos, const string&in font)
{
	GUI::SetFont(font);
	GUI::DrawTextCentered(text, pos, color_black);
}

void makeExitButton(CRules@ this, Vec2f&in pos, CControls@ controls, Vec2f&in mousePos)
{
	Vec2f tl = pos + Vec2f(-20, -20);
	Vec2f br = pos + Vec2f(20, 20);
	
	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);
		
		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			show_gamehelp = false;
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}
	GUI::DrawIcon("MenuItems", 29, Vec2f(32,32), Vec2f(pos.x-32, pos.y-32), 1.0f);
}

void makePageChangeButton(Vec2f&in pos, CControls@ controls, Vec2f&in mousePos, const bool&in right)
{
	Vec2f tl = pos + Vec2f(-20, -20);
	Vec2f br = pos + Vec2f(20, 20);
	
	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);
		
		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			if (right)
				page = page == pages - 1 ? 0 : page + 1;
			else
				page = page == 0 ? pages - 1 : page - 1;
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}
	GUI::DrawIcon("MenuItems", right ? 22 : 23, Vec2f(32,32), Vec2f(pos.x-32, pos.y-32), 1.0f);
}

void makeWebsiteLink(Vec2f pos, const string&in text, const string&in website, CControls@ controls, Vec2f&in mousePos)
{
	GUI::SetFont("medium font");
	Vec2f dim;
	GUI::GetTextDimensions(text, dim);

	const f32 width = dim.x + 20;
	const f32 height = 40;
	Vec2f tl = pos;
	Vec2f br = Vec2f(width + pos.x, pos.y + height);

	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);

		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			OpenWebsite(website);
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}

	GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
}

void drawStagingPopup(Vec2f&in pos)
{
	#ifdef STAGING
	return; //staging players don't see this popup
	#endif

	GUI::SetFont("menu");
	string info = "Staging\n\n"+
	              "Zombie Fortress is best\nsuited to be played\n"+
	              "with a staging client.\n\n"+
	              "What is Staging?\n"+
	              "Staging is a version of KAG\nwith incredible optimization.\n"+
	              "Switch to staging for\nmajor performance improvement!\n\n"+
	              "How to get staging on steam:\n"+
	              "\nKAG properties -> Betas ->\nEnter transhumandesign in form ->\nChoose staging-test branch\n\n"+
	              "Visit the discord\nfor additional information\nor if you are a non-steam player.";
	
	if (g_locale == "ru")
	{
		info = "Staging\n\n"+
		       "Zombie Fortress лучше всего работает на\n"+
		       "клиенте Staging.\n\n"+
		       "Что такое Staging?\n"+
		       "Staging - это версия оригинальной игры KAG\nс улучшенной оптимизацией.\n"+
		       "Попробуйте Staging для\nувеличения производительности!\n\n"+
		       "Как получить Staging-клиент в Steam:\n"+
		       "\nСвойства KAG -> Бета-версии ->\nВведите transhumandesign в поле ->\nВыберите ветку 'staging-test'\n\n"+
		       "Заходите на Discord-сервер\nдля получения дополнительной информации,\nесли же вы не играете через Steam.";
	}
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	
	pos.y += dim.y;
	pos.x -= 25.0f;

	Vec2f tl = pos - dim + Vec2f(-5.0f, 0.0f);
	Vec2f br = pos + Vec2f(10.0f, -40.0f);
	GUI::DrawPane(tl, br, SColor(0xffcccccc));

	pos.y += 10.0f;
	GUI::DrawText(info, pos - dim, SColor(0xffffffff));
}


const string[] lag =
{
	"lag",
	"lags",
	"laggs",
	"lag?",
	"lag!",
	"lag.",
	"lagging",
	"lagg",
	"laggy",
	"lagy",
	"fps"
};

const bool SaidLag(const string&in textIn)
{
	const string lower = textIn.toLower();
	string[] tokens = lower.split(" ");
	for (u8 i = 0; i < tokens.length; i++)
	{
		if (lag.find(tokens[i]) != -1) return true;
	}
	return false;
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	#ifdef STAGING
	return true;
	#endif

	if (player !is null && player.isMyPlayer())
	{
		if (SaidLag(textIn))
		{
			show_gamehelp = true;
		}
	}
	
	return true;
}