// Saves page for scoreboard menu

#include "CustomTiles.as"
#include "ScrollHandler.as"
#include "PlayerPermissions.as"
#include "SaveFileCommon.as"

const string SaveMapTexture = "SaveMapTexture";

string current_save_slot = "";

Component@[]@ SavesPage()
{
	CPlayer@ local_player = getLocalPlayer();

	Component@[] components;
	List@ main_container = getMainContainer();
	Pane@ page_container = getPageContainer();
	Pane@ page_selector = getPageSelector();
	
	f32[] row_sizes = {0.1f, 0.9f};
	page_container.SetRowSizes(row_sizes);
	
	Slider@ slider = StandardVerticalSlider(ui);
	slider.SetAlignment(1.0f, 0.0f);
	slider.SetMargin(5, 5);
	slider.SetStretchRatio(1.0f, 1.0f);

	List@ saves_container = StandardList(ui);
	saves_container.SetMargin(5, 5);
	saves_container.SetStretchRatio(1.0f, 1.0f);
	saves_container.SetCellWrap(3);
	float[] columnsizes = { 0.5f, 0.08f, 1 };
	saves_container.SetColumnSizes(columnsizes);

	StandardList@ saves_list = StandardList(ui);
	saves_list.SetMargin(10, 10);
	saves_list.SetStretchRatio(1.0f, 1.0f);
	saves_list.SetMaxLines(8);

	saves_list.AddEventListener(Event::ScrollIndex, ScrollHandler(slider, saves_list, false));
	slider.AddEventListener(Event::Percentage, ScrollHandler(slider, saves_list, true));

	Pane@ viewing_pane = StandardPane(ui, StandardPaneType::Framed);
	viewing_pane.SetMargin(20, 20);
	viewing_pane.SetStretchRatio(1.0f, 1.0f);
	
	Label@ header = getHeader(Translate("Saves"), "big font");
	header.SetAlignment(0.55f, 0.5f);

	List@ title_container = StandardList(ui);
	title_container.SetMargin(5, 5);
	title_container.SetStretchRatio(1.0f, 1.0f);
	title_container.SetCellWrap(2);
	float[] title_columnsizes = { 1, 0.1f };
	title_container.SetColumnSizes(title_columnsizes);

	Icon@ icon = StandardIcon("InteractionIcons", 14, Vec2f(32, 32), 0);
	icon.SetStretchRatio(1.0f, 1.0f);
	icon.SetAlignment(0.5f, 0.5f);

	Button@ info_button = InfoSelectButton(ui);
	info_button.SetMargin(10, 10);
	info_button.SetStretchRatio(1.0f, 1.0f);

	InfoHandler@ handler = InfoHandler(viewing_pane);
	info_button.AddEventListener(Event::Release, handler);
	if (current_save_slot.isEmpty())
	{
		handler.Handle();
	}
	
	info_button.AddComponent(icon);
	
	saves_container.AddComponent(saves_list);
	saves_container.AddComponent(slider);
	saves_container.AddComponent(viewing_pane);

	title_container.AddComponent(header);
	title_container.AddComponent(info_button);

	page_container.AddComponent(title_container);
	page_container.AddComponent(saves_container);

	main_container.AddComponent(page_container);
	main_container.AddComponent(page_selector);

	main_container.AddEventListener(Event::SaveMap, PageHandler(@SavesPage));

	string[] save_slots;
	ConfigFile@[] configs;
	getSaveFiles(@save_slots, @configs);

	Vec2f button_bounds = Vec2f(0, 0);
	const int count = Maths::Max(save_slots.length, 8);
	for (int i = 0; i < count; i++)
	{
		const string save_slot = save_slots.length <= i ? "" : save_slots[i];
		Button@ button = SaveSelectButton(ui, save_slot);
		button.SetPadding(10, 10);
		button.SetStretchRatio(1.0f, 1.0f);

		saves_list.AddComponent(button);
		
		if (i == 0)
		{
			button_bounds = button.getInnerBounds();
		}

		if (save_slot.isEmpty()) continue;

		const u16 day_number = configs[i].read_u16("day_number", 1);
		const s32 date_saved = configs[i].read_s32("date_saved", 0);

		Label@ save_label = getHeader(save_slot, "menu", color_white);
		save_label.SetAlignment(0.0f, 0.0f);
		save_label.SetMargin(0, 0);
		ForceTextInsideBounds(save_label, button_bounds);
		
		List@ info_container = StandardList(ui);
		info_container.SetStretchRatio(1.0f, 0.0f);
		info_container.SetCellWrap(2);

		Label@ day_label = getHeader(Translate("Day").replace("{INPUT}", day_number+""), "normal", SColor(255, 230, 230, 230));
		day_label.SetAlignment(0.0f, 0.0f);
		day_label.SetMargin(0, 0);

		const string date = date_saved == 0 ? "None" : Time_Date(date_saved);

		Label@ date_label = getHeader(date, "normal", SColor(255, 230, 230, 230));
		date_label.SetAlignment(1.0f, 0.0f);
		date_label.SetMargin(0, 0);
		
		info_container.AddComponent(day_label);
		info_container.AddComponent(date_label);

		SaveHandler@ handler = SaveHandler(viewing_pane, save_slot);
		button.AddEventListener(Event::Release, handler);

		if (current_save_slot.isEmpty() || save_slot == current_save_slot)
		{
			handler.Handle();
		}

		button.AddComponent(save_label);
		button.AddComponent(info_container);
	}

	components.push_back(main_container);
	return components;
}

class InfoSelectButton : StandardButton
{
	InfoSelectButton(EasyUI@ ui)
	{
		super(ui);
	}

	bool isDisabled()
	{
		return current_save_slot.isEmpty();
	}
}

class InfoHandler : EventHandler
{
	Pane@ viewing_pane;

	InfoHandler(Pane@ viewing_pane)
	{
		@this.viewing_pane = viewing_pane;
	}

	void Handle()
	{
		current_save_slot = "";
		float[] viewing_pane_rowsizes = { 0, 1 };
		viewing_pane.SetRowSizes(viewing_pane_rowsizes);

		Component@[] components;

		Label@ header = getHeader(Translate("SaveWorld"), "big font", color_white);
		
		List@ info_container = StandardList(ui);
		info_container.SetAlignment(0.5f, 0.0f);
		info_container.SetStretchRatio(1.0f, 0.0f);
		info_container.SetMargin(40, 20);

		Label@ line0 = getTextLine(Translate("SaveInfo0"), "menu", color_white);
		Label@ line1 = getTextLine(Translate("SaveInfo1"), "medium font", color_white);
		Label@ line2 = getTextLine(Translate("SaveInfo2"), "menu", color_white);
		
		info_container.AddComponent(line0);
		info_container.AddComponent(line1);
		info_container.AddComponent(line2);

		components.push_back(header);
		components.push_back(info_container);

		viewing_pane.SetComponents(components);
	}
}

Label@ getTextLine(const string&in text, const string&in font = "menu", SColor color = color_black)
{
	Label@ label = getHeader(text, font,color);
	label.SetAlignment(0.0f, 0.0f);
	label.SetMargin(0, 5);
	label.SetStretchRatio(1.0f, 0.0f);
	return label;
}

void ForceTextInsideBounds(Label@ label, Vec2f max_bounds)
{
	if (label.getMinBounds().x <= max_bounds.x) return;

	const string font = label.getFont();
	if (font ==  "big font")
	{
		label.SetFont("medium font");
		ForceTextInsideBounds(label, max_bounds);
	}
	else if (font == "medium font")
	{
		label.SetFont("menu");
		ForceTextInsideBounds(label, max_bounds);
	}
	else if (font == "menu")
	{
		label.SetFont("normal");
		ForceTextInsideBounds(label, max_bounds);
	}
	else
	{
		string text = label.getText();
		if (text.size() != 0)
		{
			text = text.substr(0, text.size() - 1);
			label.SetText(text);
			ForceTextInsideBounds(label, max_bounds);
		}
	}
}

class SaveHandler : EventHandler
{
	Pane@ viewing_pane;
	string save_slot;

	SaveHandler(Pane@ viewing_pane, const string&in save_slot)
	{
		@this.viewing_pane = viewing_pane;
		this.save_slot = save_slot;
	}

	void Handle()
	{
		current_save_slot = save_slot;
		float[] viewing_pane_rowsizes = { 0, 0, 1, 0.1f };
		viewing_pane.SetRowSizes(viewing_pane_rowsizes);

		ConfigFile config = ConfigFile();
		if (!config.loadFile("../Cache/" + Save::SaveFileName + save_slot)) return;

		const string[]@ map_dimensions = config.read_string("map_dimensions", "").split(";");
		if (map_dimensions.length < 2) return;

		const int width = parseInt(map_dimensions[0]);
		const int height = parseInt(map_dimensions[1]);

		MakeMapTexture(config, width, height);

		Component@[] components;

		Label@ header = getHeader(save_slot, "big font", color_white);
		header.SetMargin(10, 10);
		ForceTextInsideBounds(header, viewing_pane.getInnerBounds());

		List@ info_container = StandardList(ui);
		info_container.SetStretchRatio(1.0f, 0.0f);

		const u16 day_number = config.read_u16("day_number", 1);
		const string map_seed = config.read_string("map_seed", "None");
		const s32 date_saved = config.read_s32("date_saved", 0);

		const string date = date_saved == 0 ? "None" : Time_Date(date_saved);

		Label@ day_label = getHeader(Translate("Day").replace("{INPUT}", day_number+""), "medium font", color_white);
		Label@ seed_label = getHeader(Translate("Seed").replace("{INPUT}", map_seed), "medium font", color_white);
		Label@ date_label = getHeader(Translate("Date").replace("{INPUT}", date), "medium font", color_white);

		info_container.AddComponent(day_label);
		info_container.AddComponent(seed_label);
		info_container.AddComponent(date_label);

		Icon@ icon = MapIcon(SaveMapTexture, Vec2f(width, height));
		icon.SetStretchRatio(1.0f, 1.0f);
		icon.SetAlignment(0.5f, 0.5f);
		icon.SetMargin(5, 5);
		icon.SetMinSize(width * 0.5f, height * 0.5f);
		icon.SetMaxSize(width, height);

		Button@ button = LoadSaveButton(ui);
		button.SetPadding(10, 5);
		button.SetMargin(5, 5);
		button.SetStretchRatio(1.0f, 1.0f);

		LoadSaveHandler@ handler = LoadSaveHandler(save_slot);
		button.AddEventListener(Event::Release, handler);

		Label@ load_save_label = getHeader(Translate("LoadWorld"), "medium font", color_white);

		button.AddComponent(load_save_label);

		components.push_back(header);
		components.push_back(info_container);
		components.push_back(icon);
		components.push_back(button);

		viewing_pane.SetComponents(components);
	}
}

class SaveSelectButton : StandardButton
{
	string save_slot;

	SaveSelectButton(EasyUI@ ui, const string&in save_slot)
	{
		super(ui);
		this.save_slot = save_slot;
	}

	bool isDisabled()
	{
		return save_slot == current_save_slot || save_slot.isEmpty();
	}
}

class LoadSaveButton : StandardButton
{
	bool canLoadSave = false;

	LoadSaveButton(EasyUI@ ui)
	{
		super(ui);

		CPlayer@ player = getLocalPlayer();
		if (player is null) return;

		bool isAdmin, isSuperAdmin;
		getPermissions(player, isAdmin, isSuperAdmin);

		canLoadSave = isAdmin || isSuperAdmin;
	}

	bool isDisabled()
	{
		return !canLoadSave;
	}
}

class LoadSaveHandler : EventHandler
{
	string save_slot;

	LoadSaveHandler(const string&in save_slot)
	{
		this.save_slot = save_slot;
	}

	void Handle()
	{
		ConfigFile config = ConfigFile();
		if (!config.loadFile("../Cache/" + Save::SaveFileName + save_slot)) return;

		SaveFile@ save = SaveFile(config);

		CBitStream stream;
		save.Serialize(stream);

		CRules@ rules = getRules();
		rules.SendCommand(rules.getCommandID("server_load_save"), stream);
	}
}

bool getSaveFiles(string[]@ save_slots, ConfigFile@[]@ configs)
{
	ConfigFile saves = ConfigFile();
	if (!saves.loadFile("../Cache/" + Save::AllSavesFileName))
	{
		saves.saveFile(Save::AllSavesFileName);
	}

	bool outdated = false;

	const string all_saves = saves.read_string("all_saves", "");
	save_slots = all_saves.split(" ");

	for (int i = 0; i < save_slots.length; i++)
	{
		if (save_slots[i].isEmpty()) continue;

		ConfigFile config = ConfigFile();
		if (config.loadFile("../Cache/" + Save::SaveFileName + save_slots[i]))
		{
			configs.push_back(@config);
			continue;
		}

		outdated = true;
		save_slots.erase(i);
		i--;
	}

	if (outdated)
	{
		string updated_saves = "";
		for (int i = 0; i < save_slots.length; i++)
		{
			updated_saves += save_slots[i] + " ";
		}
		saves.add_string("all_saves", updated_saves);
		saves.saveFile(Save::AllSavesFileName);
	}

	return save_slots.length > 0;
}

void MakeMapTexture(ConfigFile@ config, const int&in width, const int&in height)
{
	const string map_data = config.read_string("map_data", "");
	const string water_data = config.read_string("water_data", "");

	const int count = width * height;
	u16[] types(count);
	bool[] water(count);
	LoadTiles(types, map_data.split(";"));
	LoadWater(water, water_data.split(";"));

	if (Texture::exists(SaveMapTexture))
	{
		Texture::destroy(SaveMapTexture);
	}

	if (!Texture::createBySize(SaveMapTexture, width, height))
	{
		error("Failed to create map texture [PageSaves]");
		return;
	}

	CMap@ map = getMap();
	ImageData@ edit = Texture::data(SaveMapTexture);

	for (int i = 0; i < count; i++)
	{
		edit[i] = CalculateMinimapColour(map, i, @types, @water, width, height);
	}

	if (!Texture::update(SaveMapTexture, edit))
	{
		error("Failed to update minimap texture [PageSaves]");
	}
}

void LoadTiles(u16[]@ types, const string[]&in map_tiles)
{
	u32 current_index = 0;
	for (int i = 0; i < map_tiles.length; i++)
	{
		if (map_tiles[i].isEmpty()) continue;

		string[]@ data = map_tiles[i].split(" ");
		if (data.length != 2) continue;

		const int tile_type = parseInt(data[0]);
		const int tile_count = parseInt(data[1]);

		for (int j = 0; j < tile_count; j++)
		{
			types[current_index++] = tile_type;
		}
	}
}

void LoadWater(bool[]@ water, const string[]&in map_tiles)
{
	u32 current_index = 0;
	for (int i = 0; i < map_tiles.length; i++)
	{
		if (map_tiles[i].isEmpty()) continue;

		string[]@ data = map_tiles[i].split(" ");
		if (data.length != 2) continue;

		const bool has_water = data[0] == "1";
		const int tile_count = parseInt(data[1]);

		for (int j = 0; j < tile_count; j++)
		{
			water[current_index++] = has_water;
		}
	}
}

const SColor color_sky(0xffedcca6);
const SColor color_solid(0xffc4873a);
const SColor color_solid_border(0xff844715);
const SColor color_background(0xfff3ac5c);
const SColor color_background_border(0xffc4873a);
const SColor color_water(0xff2cafde);

SColor CalculateMinimapColour(CMap@ map, const int&in index, u16[]@ types, bool[]@ water, const int&in width, const int&in height)
{
	SColor col;

	const u16 type = types[index];

	if (isTileSolid(map, type))
	{
		col = color_solid;

		if (!isMapBorder(index, width, height))
		{
			const int left = types[index - 1];
			const int right = types[index + 1];
			const int up = types[index - width];
			const int below = types[index + width];

			if (!isTileSolid(map, left) || 
			    !isTileSolid(map, right) ||
			    !isTileSolid(map, up) ||
			    !isTileSolid(map, below))
			{
				col = color_solid_border;
			}
		}
	}
	else if (type != CMap::tile_empty && !map.isTileGrass(type))
	{
		col = color_background;

		if (!isMapBorder(index, width, height))
		{
			const int left = types[index - 1];
			const int right = types[index + 1];
			const int up = types[index - width];
			const int below = types[index + width];

			if ((left == CMap::tile_empty) ||
			    (right == CMap::tile_empty) ||
			    (up == CMap::tile_empty) ||
			    (below == CMap::tile_empty))
			{
				col = color_background_border;
			}
		}
	}
	else
	{
		col = color_sky;
	}

	if (water[index])
	{
		col = col.getInterpolated(color_water, 0.5f);
	}

	return col;
}

bool isMapBorder(const u32&in index, const int&in width, const int&in height)
{
	return false;

	const bool left = index % width == 0;
	const bool right = index % width == width - 1;
	const bool top = index < width;
	const bool bottom = index > width * height - width;
	return left || right || top || bottom;
}

string Time_Date(u32&in time)
{
	const u32 SECONDS_PER_DAY = 86400;
	const u32 SECONDS_PER_HOUR = 3600;
	const u32 SECONDS_PER_MINUTE = 60;

	u32 days = time / SECONDS_PER_DAY;
	u32 year = 1970;

	while (true)
	{
		const bool leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
		const u32 days_in_year = leap ? 366 : 365;

		if (days >= days_in_year)
		{
			days -= days_in_year;
			year++;
		}
		else
		{
			break;
		}
	}

	u8[] month_days = {31,28,31,30,31,30,31,31,30,31,30,31};

	const bool leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

	if (leap)
	{
		month_days[1] = 29;
	}

	u32 month = 1;

	for (u8 i = 0; i < 12; i++)
	{
		if (days >= month_days[i])
		{
			days -= month_days[i];
			month++;
		}
		else
		{
			break;
		}
	}

	const u32 day = days + 1;
	u32 remaining_seconds = time % SECONDS_PER_DAY;
	const u32 hour = remaining_seconds / SECONDS_PER_HOUR;
	remaining_seconds %= SECONDS_PER_HOUR;
	const u32 minute = remaining_seconds / SECONDS_PER_MINUTE;

	return year + "/" + month + "/" + day + " " + hour + ":" + minute;
}

// Testing purposes
/*void SaveMapImage(const int width, const int height)
{
	ImageData@ edit = Texture::data(SaveMapTexture);

	CFileImage image(width, height, true);
	image.setFilename("SaveMapImage", IMAGE_FILENAME_BASE_MAPS);

	image.nextPixel();

	for (int i = 0; i < edit.size(); i++)
	{
		image.setPixelAndAdvance(edit[i]);
	}

	image.Save();
}*/
