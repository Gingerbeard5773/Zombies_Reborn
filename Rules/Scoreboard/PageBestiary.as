// Bestiary page for scoreboard menu

#include "Zombie_BestiaryCommon.as"
#include "StatisticHandler.as"
#include "ScrollHandler.as"

Component@[]@ BestiaryPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();
	
	f32[] row_sizes = {0.1f, 0.9f};
	page_container.SetRowSizes(row_sizes);

	Label@ header = getHeader(Translate("Bestiary"), "big font");
	
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

	BestiaryEntry@[]@ entries = Bestiary::getEntries();

	const string bestiary_entries = Bestiary::getArray(entries.length, Bestiary::openConfig());

	bool setup = false;

	for (u8 i = 0; i < entries.length; i++)
	{
		BestiaryEntry@ entry = entries[i];

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

	main_container.AddEventListener(Event::Bestiary, PageHandler(@BestiaryPage));

	components.push_back(main_container);
	return components;
}

class BestiaryHandler : EventHandler
{
	Pane@ viewing_pane;
	BestiaryEntry@ entry;

	BestiaryHandler(Pane@ viewing_pane, BestiaryEntry@ entry)
	{
		@this.viewing_pane = viewing_pane;
		@this.entry = entry;
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

		Label@ current_name = getHeader(Translate("CurrentGame")+" "+getTranslatedString("Kills"), "menu", color_white);
		Label@ alltime_name = getHeader(Translate("AllTime")+" "+getTranslatedString("Kills"), "menu", color_white);

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
