//Zombie Fortress scoreboard

#define CLIENT_ONLY

#include "EasyUI.as"
#include "Zombie_Translation.as"
#include "Zombie_GlobalMessagesCommon.as"

// Register Pages
#include "PageStatistics.as"
#include "PageAchievements.as"
#include "PageBestiary.as"
#include "PageSaves.as"

const f32 scoreboardMargin = 52.0f;
const f32 scrollSpeed = 4.0f;
const f32 maxMenuWidth = 380;

u32 copy_time = 0;
string copy_name = "";
Vec2f copy_pos = Vec2f_zero;

f32 scrollOffset = 0.0f;
bool mousePress = false;

EasyUI@ ui;

funcdef Component@[]@ PageHandle();

PageHandle@ current_page;

void onInit(CRules@ this)
{
	SetupUI(this);
	int render_id = Render::addScript(Render::layer_posthud, "Zombie_Scoreboard.as", "RenderScoreboard", 0.0f);
}

void onReload(CRules@ this)
{
	SetupUI(this);
}

void SetupUI(CRules@ this)
{
	@ui = EasyUI();

	@current_page = @ScoreboardPage;

	ui.SetComponents(current_page());

	Event[] events;
	this.set("easy_ui_events", events);
}

void onTick(CRules@ this)
{
	if (!isPlayerListShowing()) return;

	ui.Update();

	Event[]@ events;
	if (this.get("easy_ui_events", @events) && events.length > 0)
	{
		Component@[]@ components = ui.GetComponents();
		for (uint i = 0; i < components.length; i++)
		{
			components[i].DispatchEvent(events[0]);
		}
		events.erase(0);
	}
}

List@ getMainContainer()
{
	// The list that holds everything
	List@ main_container = StandardList(ui);
	main_container.SetMargin(5, 5);
	main_container.SetPadding(5, 5);
	main_container.SetAlignment(0.5f, 0.5f);
	main_container.SetStretchRatio(1.0f, 0.0f);
	main_container.SetMaxSize(800, 400);
	return main_container;
}

Pane@ getPageContainer()
{
	// The standard page pane
	Pane@ page_container = StandardPane(ui, StandardPaneType::Window);
	page_container.SetMargin(5, 5);
	page_container.SetPadding(5, 5);
	page_container.SetAlignment(0.5f, 0.0f);
	page_container.SetStretchRatio(0.0f, 0.0f);
	page_container.SetMinSize(800, 550);
	page_container.SetMaxSize(800, 550);
	return page_container;
}

Pane@ getPageSelector()
{
	// The pane that holds the page selection buttons
	Pane@ page_selector = StandardPane(ui, StandardPaneType::Normal);
	page_selector.SetMargin(5, 5);
	page_selector.SetPadding(5, 5);
	page_selector.SetAlignment(0.5f, 0.0f);
	page_selector.SetStretchRatio(1.0f, 1.0f);
	page_selector.SetCellWrap(6);
	page_selector.SetMaxSize(800, 20);

	Button@ page0 = getPageButton(Translate("Scoreboard"),   PageHandler(@ScoreboardPage));
	Button@ page1 = getPageButton(Translate("Statistics"),   PageHandler(@StatisticsPage));
	Button@ page2 = getPageButton(Translate("Achievements"), PageHandler(@AchievementsPage));
	Button@ page3 = getPageButton(Translate("Bestiary"),     PageHandler(@BestiaryPage));
	//Button@ page4 = getPageButton(Translate("Settings"),     PageHandler(@SettingsPage));
	Button@ page5 = getPageButton(Translate("Saves"),        PageHandler(@SavesPage));

	page_selector.AddComponent(page0);
	page_selector.AddComponent(page1);
	page_selector.AddComponent(page2);
	page_selector.AddComponent(page3);
	//page_selector.AddComponent(page4);
	page_selector.AddComponent(page5);

	return page_selector;
}

Button@ getPageButton(const string&in name, PageHandler@ handler)
{
	// A button that changes the page
	Label@ label = StandardLabel();
	label.SetText(name);
	label.SetAlignment(0.5f, 0.5f);

	PageSelectButton@ button = PageSelectButton(ui, handler.page);
	button.SetPadding(20, 8);
	button.SetSpacing(10, 10);
	button.SetStretchRatio(1.0f, 1.0f);
	button.AddComponent(label);

	button.AddEventListener(Event::Release, handler);

	return button;
}

Label@ getHeader(const string&in text, const string&in font = "menu", SColor color = color_black)
{
	Label@ label = StandardLabel();
	label.SetAlignment(0.5f, 0.0f);
	label.SetMargin(0, 5);
	label.SetStretchRatio(1.0f, 0.0f);
	label.SetFont(font);
	label.SetText(text);
	label.SetColor(color);
	return label;
}

class PageSelectButton : StandardButton
{
	PageHandle@ page;

	PageSelectButton(EasyUI@ ui, PageHandle@ page)
	{
		super(ui);
		@this.page = page;
	}

	bool isDisabled()
	{
		return page is current_page;
	}
}

class PageHandler : EventHandler
{
	PageHandle@ page;

	PageHandler(PageHandle@ page)
	{
		@this.page = page;
	}

	void Handle()
	{
		@current_page = page;

		ui.GetComponents().clear();
		ui.SetComponents(current_page());
	}
}

Component@[]@ ScoreboardPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_selector = getPageSelector();

	main_container.AddComponent(page_selector);

	components.push_back(main_container);
	return components;
}

/// SCOREBOARD

//returns the bottom
const f32 drawScoreboard(CPlayer@[]@ players, Vec2f&in topleft, const u8&in teamNum, const f32&in screenMidX, const string&in teamName)
{
	CRules@ rules = getRules();
	CTeam@ team = rules.getTeam(teamNum);

	const u8 playersLength = players.length;
	if (playersLength <= 0 || team is null) return topleft.y;

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
	GUI::DrawText(teamName, topleft, color_white);
	
	const string playercount = getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + playersLength);
	const string zombiecount = Translate("Zombies").replace("{AMOUNT}", rules.get_u16("undead count") + "");
	const string zombiekills = Translate("TotalKills").replace("{INPUT}", rules.get_u32("undead_killed_total") + "");
	
	GUI::DrawText(playercount, Vec2f(topleft.x + 150, topleft.y), color_white);
	GUI::DrawText(zombiecount, Vec2f(topleft.x + 300, topleft.y), color_white);
	GUI::DrawText(zombiekills, Vec2f(topleft.x + 450, topleft.y), color_white);

	topleft.y += stepheight * 2;
	
	//draw player table header
	
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x, topleft.y), color_white);
	GUI::DrawText(getTranslatedString("Username"), Vec2f(bottomright.x - 440, topleft.y), color_white);
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 270, topleft.y), color_white);
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 200, topleft.y), color_white);
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 120, topleft.y), color_white);

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
		GUI::DrawText("" + p.getKills(), Vec2f(bottomright.x - 270, topleft.y), color_white);
		GUI::DrawText("" + p.getDeaths(), Vec2f(bottomright.x - 200, topleft.y), color_white);
		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 120, topleft.y), color_white);
	}

	// username copied text, goes at bottom to overlay above everything else
	if ((copy_time + 64) > getGameTime())
	{
		drawFancyCopiedText();
	}

	return topleft.y;
}

void onRenderScoreboard(CRules@ this)
{
	//override engine
}

void RenderScoreboard(int render_id)
{
	if (!isPlayerListShowing()) return;

	if (ui is null) return;

	ui.Render();

	if (g_debug == 1)
	{
		if (getControls().isKeyPressed(KEY_LCONTROL) || getControls().isKeyPressed(KEY_LSHIFT))
		{
			ui.Debug(getControls().isKeyPressed(KEY_LSHIFT));
		}
	}

	if (current_page !is @ScoreboardPage) return;

	CRules@ this = getRules();
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
	Vec2f topleft(Maths::Max(100, screenMidX-maxMenuWidth), 150);
	drawServerInfo(this, screenMidX, 40);

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

	makeZombieScoreboardButton(topleft + Vec2f(0, -70), "Discord", "https://discord.gg/V29BBeba3C", controls, mousePos);
	makeZombieScoreboardButton(topleft + Vec2f(100, -70), "Github", "https://github.com/Gingerbeard5773/Zombies_Reborn", controls, mousePos);

	drawStagingPopup(topleft);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//draw the scoreboard
	GUI::SetFont("menu");

	topleft.y = drawScoreboard(survivors, topleft, 0, screenMidX, Translate("Survivors"));
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

	const float screenHeight = getScreenHeight();

	Component@[]@ components = ui.GetComponents();
	for (uint i = 0; i < components.length; i++)
	{
		Component@ component = components[i];
		component.SetAlignment(component.getAlignment().x, topleft.y / screenHeight);
	}

	const float scoreboardHeight = topleft.y + scrollOffset;

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

	const string info = Translate("ZF");
	const string seed = Translate("Seed").replace("{INPUT}", this.get_string("map_name"));
	const string dayRecord = Translate("AllTimeRecord").replace("{INPUT}", this.get_u16("day_record")+"");
	const string dayCount = Translate("DayNum").replace("{DAYS}", this.get_u16("day_number")+"");
	
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	if (dim.x + 15 > width) width = dim.x + 15;

	GUI::GetTextDimensions(seed, dim);
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
	GUI::DrawTextCentered(seed, mid, color_white);
	mid.y += 25;
	GUI::DrawTextCentered(dayRecord, mid, color_white);
	mid.y += 25;
	GUI::DrawTextCentered(dayCount, mid, color_white);
}

void makeZombieScoreboardButton(Vec2f pos, const string&in text, const string&in website, CControls@ controls, Vec2f&in mousePos)
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

	GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), color_white);
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
	GUI::DrawText(info, pos - dim, color_white);
}

const string[] lag =
{
	"lag", "lags", "laggs", "lag?", "lag!", "lag.", "lagging", "lagg", "laggy", "lagy", "fps"
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
			const string info = g_locale == "ru" ? "Посетите таблицу результатов, чтобы узнать, как устранить задержки в игре." : 
			                                       "Visit the scoreboard to read how to resolve lag.";
			client_SendGlobalMessage(this, info, 10, ConsoleColour::WARNING.color);
		}
	}
	
	return true;
}
