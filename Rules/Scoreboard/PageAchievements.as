// Achievements page for scoreboard menu

#include "Zombie_AchievementsCommon.as"
#include "ScrollHandler.as"

Component@[]@ AchievementsPage()
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
	
	const string achievements_array = Achievement::getArray(Achievement::Count, Achievement::openConfig());

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

	Achievement@[]@ achievements = Achievement::getAchievements();

	u8 unlocked_count = 0;
	for (u8 i = 0; i < achievements.length; i++)
	{
		Achievement@ achievement = achievements[i];

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

	Label@ header = getHeader(Translate("Achievements"), "big font");
	header.SetMargin(0, 0);

	achievements_container.AddComponent(achievements_list);
	achievements_container.AddComponent(achievements_slider);

	page_container.AddComponent(header);
	page_container.AddComponent(achievements_container);
	page_container.AddComponent(progress);

	main_container.AddComponent(page_container);
	main_container.AddComponent(page_selector);

	main_container.AddEventListener(Event::Achievement, PageHandler(@AchievementsPage));

	components.push_back(main_container);
	return components;
}
