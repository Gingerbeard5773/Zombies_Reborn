//Zombie Fortress scoreboard

#define CLIENT_ONLY

#include "EasyUI.as"
#include "Zombie_Translation.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"
#include "Zombie_BestiaryCommon.as"

const f32 scoreboardMargin = 52.0f;
const f32 scrollSpeed = 4.0f;
const f32 maxMenuWidth = 380;

u32 copy_time = 0;
string copy_name = "";
Vec2f copy_pos = Vec2f_zero;

f32 scrollOffset = 0.0f;
bool mouseWasPressed2 = false;
bool mousePress = false;

EasyUI@ ui;
u8 page_num;

void onInit(CRules@ this)
{
	SetupUI(this);
}

void onReload(CRules@ this)
{
	SetupUI(this);
}

void SetupUI(CRules@ this)
{
	@ui = EasyUI();

	page_num = 0;

	ui.SetComponents(getScoreboardPage());

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
	page_selector.SetCellWrap(4);
	page_selector.SetMaxSize(800, 20);
	Button@ page1 = getPageButton(Translate::Scoreboard,   PageHandler(0));
	Button@ page2 = getPageButton(Translate::Statistics,   PageHandler(1));
	Button@ page3 = getPageButton(Translate::Achievements, PageHandler(2));
	Button@ page4 = getPageButton(Translate::Bestiary,     PageHandler(3));
	page_selector.AddComponent(page1);
	page_selector.AddComponent(page2);
	page_selector.AddComponent(page3);
	page_selector.AddComponent(page4);
	return page_selector;
}

Button@ getPageButton(const string&in name, PageHandler@ handler)
{
	// A button that changes the page
	Label@ label = StandardLabel();
	label.SetText(name);
	label.SetAlignment(0.5f, 0.5f);

	PageSelectButton@ button = PageSelectButton(ui, handler.num);
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
	u8 num;

	PageSelectButton(EasyUI@ ui, const u8&in num)
	{
		super(ui);
		this.num = num;
	}

	bool isDisabled()
	{
		return num == page_num;
	}
}

class PageHandler : EventHandler
{
	u8 num;
	bool update;

	PageHandler(const u8&in num, const bool&in update = false)
	{
		this.num = num;
		this.update = update;
	}

	void Handle()
	{
		if (page_num == num && !update) return;

		page_num = num;

		ui.GetComponents().clear();
		
		Component@[]@ components;
		switch(page_num)
		{
			case 0: @components = getScoreboardPage();   break;
			case 1: @components = getStatisticsPage();   break;
			case 2: @components = getAchievementsPage(); break;
			case 3: @components = getBestiaryPage();     break;
		}

		ui.SetComponents(components);
	}
}

Component@[]@ getScoreboardPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_selector = getPageSelector();

	main_container.AddComponent(page_selector);

	components.push_back(main_container);
	return components;
}

Component@[]@ getStatisticsPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();

	Label@ header = getHeader(Translate::Statistics, "big font");

	float[] row_sizes = { 0, 1 };
	page_container.SetRowSizes(row_sizes);

	List@ statistics_container = StandardList(ui);
	statistics_container.SetMargin(5, 5);
	statistics_container.SetStretchRatio(1.0f, 1.0f);
	statistics_container.SetCellWrap(2);
	float[] statistics_container_columnsizes = { 1, 0.05f };
	statistics_container.SetColumnSizes(statistics_container_columnsizes);

	Pane@ statistics_pane = StandardPane(ui, StandardPaneType::Framed);
	statistics_pane.SetMargin(20, 20);
	statistics_pane.SetPadding(5, 5);
	statistics_pane.SetStretchRatio(1.0f, 1.0f);
	f32[] statistics_pane_row_sizes = {0.1f, 0.9f};
	statistics_pane.SetRowSizes(statistics_pane_row_sizes);
	
	StandardList@ statistics_list = StandardList(ui);
	statistics_list.SetMargin(5, 5);
	statistics_list.SetStretchRatio(1.0f, 1.0f);
	statistics_list.SetMaxLines(10);

	Slider@ statistics_slider = StandardVerticalSlider(ui);
	statistics_slider.SetAlignment(1.0f, 0.0f);
	statistics_slider.SetMargin(5, 5);
	statistics_slider.SetStretchRatio(1.0f, 1.0f);

	statistics_list.AddEventListener(Event::ScrollIndex, ScrollHandler(statistics_slider, statistics_list, false));
	statistics_slider.AddEventListener(Event::Percentage, ScrollHandler(statistics_slider, statistics_list, true));

	Label@ statistic_header = getHeader(Translate::Statistic, "medium font", color_white);
	Label@ current_header = getHeader(Translate::CurrentGame, "medium font", color_white);
	Label@ alltime_header = getHeader(Translate::AllTime, "medium font", color_white);

	List@ header_container = getStatisticContainer();
	header_container.AddComponent(statistic_header);
	header_container.AddComponent(current_header);
	header_container.AddComponent(alltime_header);

	statistics_pane.AddComponent(header_container);
	statistics_pane.AddComponent(statistics_list);

	for (u8 i = 0; i < Statistics::statistic_names.length; i++)
	{
		const string name = Statistics::statistic_names[i];

		List@ line_container = getStatisticContainer();

		Label@ statistic_name = getHeader(Statistics::statistic_translate[i], "medium font", color_white);
		Label@ statistic_current = getHeader("", "medium font", color_white);
		Label@ statistic_alltime = getHeader("", "medium font", color_white);

		StatisticHandler@ current_handler = StatisticHandler(statistic_current, name, Statistics::Current);
		StatisticHandler@ alltime_handler = StatisticHandler(statistic_alltime, name, Statistics::AllTime);

		statistic_current.AddEventListener(Event::Update, current_handler);
		statistic_alltime.AddEventListener(Event::Update, alltime_handler);

		line_container.AddComponent(statistic_name);
		line_container.AddComponent(statistic_current);
		line_container.AddComponent(statistic_alltime);

		current_handler.UpdateStatisticValue();
		alltime_handler.UpdateStatisticValue();

		statistics_list.AddComponent(line_container);
	}
	
	statistics_container.AddComponent(statistics_pane);
	statistics_container.AddComponent(statistics_slider);

	page_container.AddComponent(header);
	page_container.AddComponent(statistics_container);

	main_container.AddComponent(page_container);
	main_container.AddComponent(page_selector);

	components.push_back(main_container);
	return components;
}

List@ getStatisticContainer()
{
	List@ container = StandardList(ui);
	container.SetStretchRatio(1.0f, 1.0f);
	container.SetCellWrap(3);
	float[] statistics_pane_columnsizes = { 0.4f, 0.3f, 0.3f };
	container.SetColumnSizes(statistics_pane_columnsizes);
	return container;
}

class StatisticHandler : EventHandler
{
	Label@ label;
	string name;
	Statistics::Type type;

	StatisticHandler(Label@ label_, const string&in name, const Statistics::Type&in type)
	{
		@label = label_;
		this.name = name;
		this.type = type;
	}

	void Handle()
	{
		if (getGameTime() % 60 != 0) return; //only update every 2 seconds

		UpdateStatisticValue();
	}

	void UpdateStatisticValue()
	{
		const u32 stat_value = Statistics::Get(name, type);

		string stat = stat_value + "";

		if (name == "play_time")
		{
			f32 hours = f32(stat_value) / 3600.0f;
			hours = Maths::Roundf(hours * 10.0f) / 10.0f;

			stat = hours + " " + getTranslatedString("h ");
		}

		label.SetText(stat);
	}
}

Component@[]@ getAchievementsPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();

	SColor dark_grey = SColor(255, 50, 50, 50);
	SColor grey = SColor(255, 150, 150, 150);
	SColor light_grey = SColor(255, 200, 200, 200);

	f32[] row_sizes = {0.1f, 0.9f};
	page_container.SetRowSizes(row_sizes);

	List@ achievements_container = StandardList(ui);
	achievements_container.SetMargin(5, 5);
	achievements_container.SetStretchRatio(1.0f, 1.0f);
	achievements_container.SetCellWrap(2);
	float[] achievements_columnsizes = { 1, 0.05f };
	achievements_container.SetColumnSizes(achievements_columnsizes);
	
	const string achievements_array = Achievement::getArray(Achievement::Count);

	StandardList@ achievements_list = StandardList(ui);
	achievements_list.SetMargin(10, 5);
	achievements_list.SetStretchRatio(1.0f, 1.0f);
	achievements_list.SetMaxLines(5);

	Slider@ achievements_slider = StandardVerticalSlider(ui);
	achievements_slider.SetAlignment(1.0f, 0.0f);
	achievements_slider.SetMargin(5, 5);
	achievements_slider.SetStretchRatio(1.0f, 1.0f);

	achievements_list.AddEventListener(Event::ScrollIndex, ScrollHandler(achievements_slider, achievements_list, false));
	achievements_slider.AddEventListener(Event::Percentage, ScrollHandler(achievements_slider, achievements_list, true));

	u8 unlocked_count = 0;
	for (u8 i = 0; i < Achievement::achievements.length; i++)
	{
		Achievement@ achievement = Achievement::achievements[i];

		const bool unlocked = Achievement::isUnlocked(achievements_array, achievement.id);
		if (unlocked) unlocked_count++;

		Pane@ pane = StandardPane(ui, unlocked ? light_grey : grey);
		pane.SetPadding(0, 2);
		pane.SetStretchRatio(1.0f, 1.0f);
		pane.SetCellWrap(2);
		float[] pane_columnsizes = { 0.15f, 1 };
		pane.SetColumnSizes(pane_columnsizes);

		Icon@ icon = StandardIcon("Achievements", achievement.id, Vec2f(32, 32));
		icon.SetStretchRatio(1.0f, 1.0f);

		if (!unlocked)
		{
			icon.SetColor(SColor(255, 120, 130, 120));

			if (achievement.hidden)
			{
				icon.SetTexture("InteractionIcons");
				icon.SetTeam(255);
				icon.SetFrameIndex(14);
			}
		}
		
		Pane@ icon_pane = StandardPane(ui, StandardPaneType::Sunken);
		icon_pane.SetPadding(0, 0);
		icon_pane.SetMargin(4, 4);
		icon_pane.SetStretchRatio(1.0f, 1.0f);
		icon_pane.SetMinSize(75, 75);
		icon_pane.SetMaxSize(75, 75);
		icon_pane.AddComponent(icon);

		const string header = unlocked || !achievement.hidden  ? name(achievement.description) : "???";
		Label@ achievement_name = getHeader(header, "medium font", unlocked ? achievement.rarity : dark_grey);
		achievement_name.SetMargin(0, 10);
		achievement_name.SetAlignment(0.0f, 0.0f);

		const string description = unlocked || !achievement.hidden ? desc(achievement.description) : "???";
		Label@ achievement_description = getHeader(description, "menu", unlocked ? color_white : dark_grey);
		achievement_description.SetMargin(0, 0);
		achievement_description.SetAlignment(0.0f, 0.0f);

		List@ labels_container = StandardList(ui);
		labels_container.AddComponent(achievement_name);
		labels_container.AddComponent(achievement_description);

		pane.AddComponent(icon_pane);
		pane.AddComponent(labels_container);

		achievements_list.AddComponent(pane);
	}

	const f32 unlocked_percent = f32(unlocked_count) / f32(Achievement::Count);

	Progress@ progress = StandardProgress(ui, SColor(0xff66C6FF));
	progress.SetStretchRatio(0.5f, 1.0f);
	progress.SetAlignment(0.5f, 0.5f);
	progress.SetMaxSize(800, 20);
	progress.SetPercentage(unlocked_percent);

	Label@ progress_label = getHeader(int(unlocked_percent*100)+"%", "medium font", color_white);
	progress_label.SetMargin(0, 0);
	progress_label.SetAlignment(0.5f, 0.5f);

	progress.AddComponent(progress_label);

	Label@ header = getHeader(Translate::Achievements, "big font");
	header.SetMargin(0, 0);

	achievements_container.AddComponent(achievements_list);
	achievements_container.AddComponent(achievements_slider);

	page_container.AddComponent(header);
	page_container.AddComponent(achievements_container);
	page_container.AddComponent(progress);

	main_container.AddComponent(page_container);
	main_container.AddComponent(page_selector);

	main_container.AddEventListener(Event::Achievement, PageHandler(2, true));

	components.push_back(main_container);
	return components;
}

bool isScrollLock = false;

class ScrollHandler : EventHandler
{
	Slider@ slider;
	StandardList@ list;
	bool isSlider;
	ScrollHandler(Slider@ slider_, StandardList@ list_, const bool&in isSlider)
	{
		@slider = slider_;
		@list = list_;
		this.isSlider = isSlider;
	}

	void Handle()
	{
		if (isScrollLock) return;
		isScrollLock = true;
		// couple a slider to a list and vice versa
		const int max_scroll_index = Maths::Max(0, list.getAllComponents().length - list.getMaxLines());
		if (isSlider)
		{
			const int closest_index = Maths::Clamp(int(f32(max_scroll_index) * slider.getPercentage()),0, max_scroll_index);

			if (closest_index != list.getScrollIndex())
			{
				list.SetScrollIndex(closest_index);
			}
		}
		else if (max_scroll_index > 0)
		{
			const f32 percent = f32(list.getScrollIndex()) / f32(max_scroll_index);

			if (Maths::Abs(slider.getPercentage() - percent) > 0.001f)
			{
				slider.SetPercentage(percent);
			}
		}
		isScrollLock = false;
	}
}

Component@[]@ getBestiaryPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();
	
	f32[] row_sizes = {0.1f, 0.9f};
	page_container.SetRowSizes(row_sizes);

	Label@ header = getHeader(Translate::Bestiary, "big font");
	
	Slider@ bestiary_slider = StandardVerticalSlider(ui);
	bestiary_slider.SetAlignment(1.0f, 0.0f);
	bestiary_slider.SetMargin(5, 5);
	bestiary_slider.SetStretchRatio(1.0f, 1.0f);

	List@ bestiary_container = StandardList(ui);
	bestiary_container.SetMargin(5, 5);
	bestiary_container.SetStretchRatio(1.0f, 1.0f);
	bestiary_container.SetCellWrap(3);
	float[] bestiary_columnsizes = { 0.3f, 0.07f, 1 };
	bestiary_container.SetColumnSizes(bestiary_columnsizes);

	StandardList@ bestiary_list = StandardList(ui);
	bestiary_list.SetMargin(10, 10);
	bestiary_list.SetStretchRatio(1.0f, 1.0f);
	bestiary_list.SetMaxLines(3);

	bestiary_list.AddEventListener(Event::ScrollIndex, ScrollHandler(bestiary_slider, bestiary_list, false));
	bestiary_slider.AddEventListener(Event::Percentage, ScrollHandler(bestiary_slider, bestiary_list, true));

	Pane@ viewing_pane = StandardPane(ui, StandardPaneType::Framed);
	viewing_pane.SetMargin(20, 20);
	viewing_pane.SetStretchRatio(1.0f, 1.0f);

	const string bestiary_entries = Bestiary::getArray(Bestiary::entries.length, Bestiary::openConfig());

	bool setup = false;

	for (u8 i = 0; i < Bestiary::entries.length; i++)
	{
		BestiaryEntry@ entry = Bestiary::entries[i];

		Button@ icon_button = StandardButton(ui);
		icon_button.SetPadding(10, 10);
		icon_button.SetStretchRatio(1.0f, 1.0f);

		Icon@ icon = StandardIcon(entry.filename, entry.frames[0], entry.frame_dimension, entry.team);
		icon.SetStretchRatio(1.0f, 1.0f);
		icon.SetAlignment(0.5f, 0.5f);

		const bool unlocked = Bestiary::isUnlocked(bestiary_entries, i);
		if (!unlocked)
		{
			icon.SetTexture("InteractionIcons");
			icon.SetTeam(255);
			icon.SetFrameIndex(14);
			icon.SetFrameDim(32, 32);
			icon.SetColor(SColor(255, 120, 130, 120));
		}
		else
		{
			icon.SetMaxSize(500, entry.frame_dimension.y * 5.0f);

			BestiaryHandler@ handler = BestiaryHandler(viewing_pane, entry);
			icon_button.AddEventListener(Event::Release, handler);

			if (!setup)
			{
				setup = true;
				handler.Handle();
			}
		}
		
		Label@ entry_num = getHeader(i+"", "medium font", color_white);
		entry_num.SetAlignment(1.0f, 1.0f);
		icon.AddComponent(entry_num);

		icon_button.AddComponent(icon);
		bestiary_list.AddComponent(icon_button);
	}

	bestiary_container.AddComponent(bestiary_list);
	bestiary_container.AddComponent(bestiary_slider);
	bestiary_container.AddComponent(viewing_pane);

	page_container.AddComponent(header);
	page_container.AddComponent(bestiary_container);

	main_container.AddComponent(page_container);
	main_container.AddComponent(page_selector);

	main_container.AddEventListener(Event::Bestiary, PageHandler(3, true));

	components.push_back(main_container);
	return components;
}

class BestiaryHandler : EventHandler
{
	Pane@ viewing_pane;
	BestiaryEntry@ entry;

	BestiaryHandler(Pane@ viewing_pane_, BestiaryEntry@ entry_)
	{
		@viewing_pane = viewing_pane_;
		@entry = entry_;
	}

	void Handle()
	{
		float[] viewing_pane_rowsizes = { 0, 1, 0.1f};
		viewing_pane.SetRowSizes(viewing_pane_rowsizes);

		Component@[] components;

		Label@ header = getHeader(name(entry.description), "big font", color_white);

		AnimatedIcon@ icon = AnimatedIcon(entry.filename, entry.frames[0], entry.frame_dimension, entry.team);
		icon.SetFrames(entry.frames);
		icon.SetStretchRatio(1.0f, 1.0f);
		icon.SetAlignment(0.5f, 0.5f);
		icon.SetMargin(5, 5);
		icon.SetMinSize(entry.frame_dimension.x, entry.frame_dimension.y);
		icon.SetMaxSize(entry.frame_dimension.x * 5.0f, entry.frame_dimension.y * 5.0f);

		Label@ description = getHeader(desc(entry.description), "menu", color_white);
		description.SetWrap(true);
		description.SetMinSize(200, 70);
		description.SetMaxSize(400, 70);
		description.SetMargin(20, 20);
		description.SetAlignment(0.5f, 0.0f);
		description.SetStretchRatio(1.0f, 1.0f);

		List@ stats_container = StandardList(ui);
		stats_container.SetMargin(5, 5);
		stats_container.SetStretchRatio(1.0f, 1.0f);
		stats_container.SetCellWrap(2);
		stats_container.SetMinSize(300, 40);

		List@ current_container = StandardList(ui);
		current_container.SetStretchRatio(1.0f, 1.0f);

		List@ alltime_container = StandardList(ui);
		alltime_container.SetStretchRatio(1.0f, 1.0f);

		Label@ current_name = getHeader(Translate::CurrentGame+" "+getTranslatedString("Kills"), "menu", color_white);
		Label@ alltime_name = getHeader(Translate::AllTime+" "+getTranslatedString("Kills"), "menu", color_white);

		Label@ statistic_current = getHeader("", "menu", color_white);
		Label@ statistic_alltime = getHeader("", "menu", color_white);

		StatisticHandler@ current_handler = StatisticHandler(statistic_current, entry.name, Statistics::Current);
		StatisticHandler@ alltime_handler = StatisticHandler(statistic_alltime, entry.name, Statistics::AllTime);

		statistic_current.AddEventListener(Event::Update, current_handler);
		statistic_alltime.AddEventListener(Event::Update, alltime_handler);

		current_handler.UpdateStatisticValue();
		alltime_handler.UpdateStatisticValue();

		current_container.AddComponent(current_name);
		alltime_container.AddComponent(alltime_name);

		current_container.AddComponent(statistic_current);
		alltime_container.AddComponent(statistic_alltime);

		stats_container.AddComponent(current_container);
		stats_container.AddComponent(alltime_container);

		components.push_back(header);
		components.push_back(icon);
		components.push_back(description);
		components.push_back(stats_container);
		viewing_pane.SetComponents(components);
	}
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
	const string zombiecount = Translate::Zombies.replace("{AMOUNT}", rules.get_u16("undead count") + "");
	const string zombiekills = Translate::TotalKills.replace("{INPUT}", rules.get_u32("undead_killed_total") + "");
	
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
	if (ui is null) return;

	ui.Render();

	if (page_num != 0) return;

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

	const string info = Translate::ZF;
	const string mapName = getTranslatedString("Map: {MAP}").replace("{MAP}", this.get_string("map_name"));
	const string dayRecord = Translate::AllTimeRecord.replace("{INPUT}", this.get_u16("day_record")+"");
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
