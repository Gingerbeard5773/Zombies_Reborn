// Statistics page for scoreboard menu

#include "StatisticHandler.as"
#include "ScrollHandler.as"

Component@[]@ StatisticsPage()
{
	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();

	Label@ header = getHeader(Translate("Statistics"), "big font");

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

	Label@ statistic_header = getHeader(Translate("Statistic"), "medium font", color_white);
	Label@ current_header = getHeader(Translate("CurrentGame"), "medium font", color_white);
	Label@ alltime_header = getHeader(Translate("AllTime"), "medium font", color_white);

	List@ header_container = getStatisticContainer();
	header_container.AddComponent(statistic_header);
	header_container.AddComponent(current_header);
	header_container.AddComponent(alltime_header);

	statistics_pane.AddComponent(header_container);
	statistics_pane.AddComponent(statistics_list);

	const string[]@ statistic_names = Statistics::getNames();
	const string[]@ statistic_translate = Statistics::getDescriptions();

	for (u8 i = 0; i < statistic_names.length; i++)
	{
		const string name = statistic_names[i];

		List@ line_container = getStatisticContainer();

		Label@ statistic_name = getHeader(statistic_translate[i], "medium font", color_white);
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
