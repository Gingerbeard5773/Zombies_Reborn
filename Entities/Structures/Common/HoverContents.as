// Gingerbeard @ January 1st, 2025

// View valuable contents of a storage remotely by hovering with cursor while pressing E

#define CLIENT_ONLY

void onRender(CSprite@ this)
{
	CBlob@ playerblob = getLocalPlayerBlob();
	if (playerblob is null) return;

	CControls@ controls = getControls();
	if (controls is null) return;
	
	CCamera@ camera = getCamera();
	if (camera is null) return;

	if (!controls.isKeyPressed(KEY_KEY_E) || getHUD().hasMenus()) return;

	CBlob@ blob = this.getBlob();
	if (playerblob.getTeamNum() != blob.getTeamNum()) return;

	const f32 radius = blob.getRadius();
	Vec2f pos = blob.getPosition();

	//if ((playerblob.getPosition() - pos).getLength() < radius + 16.0f) return;

	Vec2f mouseworld = getControls().getMouseWorldPos();
	const bool mouseOnBlob = (mouseworld - pos).getLength() < radius;
	if (!mouseOnBlob) return;
	
	CInventory@ inv = blob.getInventory();
	const u16 items_count = inv.getItemsCount();
	
	string[] names;
	CBlob@[] blobs;
	
	for (u16 i = 0; i < items_count; i++)
	{
		CBlob@ item = inv.getItem(i);
		const bool isScroll = item.exists("scroll defname0");

		if (isValuable(item) || isScroll)
		{
			const string name = isScroll ? "scroll_" + item.get_string("scroll defname0") : item.getName();
			if (names.find(name) != -1) continue;

			names.push_back(name);
			blobs.push_back(item);
		}
	}
	
	if (blobs.length == 0) return;
	
	const f32 scale = camera.targetDistance;

	Vec2f base_pos = blob.getScreenPos() + Vec2f(0, -120 * scale);
	Vec2f pane_padding(8, 8);
	const f32 min_pane_height = 32 + pane_padding.y;

	f32 total_width = 0.0f;

	for (u16 i = 0; i < blobs.length; i++)
	{
		Vec2f icon_dim = blobs[i].inventoryFrameDimension * 2.0f;
		total_width += icon_dim.x + pane_padding.x;
	}

	Vec2f draw_pos = base_pos;
	draw_pos.x -= total_width * 0.5f;

	for (u16 i = 0; i < blobs.length; i++)
	{
		CBlob@ item = blobs[i];

		Vec2f icon_dim = item.inventoryFrameDimension * 2.0f;
		const f32 pane_height = Maths::Max(min_pane_height, icon_dim.y + pane_padding.y);
		Vec2f pane_size(icon_dim.x + pane_padding.x, pane_height);
		Vec2f tl = draw_pos;
		Vec2f br = draw_pos + pane_size;

		GUI::DrawButtonPressed(tl, br);

		Vec2f icon_pos = draw_pos + (pane_size - icon_dim) * 0.5f;

		GUI::DrawIconByName(getIconName(item, names[i]), icon_pos, 1.0f, 1.0f, blob.getTeamNum(), color_white);

		draw_pos.x += pane_size.x;
	}
}

string getIconName(CBlob@ item, const string&in name)
{
	if (item.exists("equipment_icon")) return item.get_string("equipment_icon");

	const string inventory_icon = "$" + item.getInventoryName() + "$";
	if (GUI::hasIconName(inventory_icon)) return inventory_icon;

	return "$" + name + "$";
}

bool isValuable(CBlob@ item)
{
	const string name = item.getName();
	if (name == "holygrenade" || name == "chainsaw" || name == "spear" || name == "partisan") return true;

	if (name == "bucket") return false;

	return item.hasTag("gun") || item.exists("equipment_slot");
}
