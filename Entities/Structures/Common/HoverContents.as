// Gingerbeard @ January 1st, 2025

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

	if ((playerblob.getPosition() - pos).getLength() < radius + 16.0f) return;

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
		if (!item.exists("scroll defname0")) continue;

		const string name = item.get_string("scroll defname0");
		if (names.find(name) != -1) continue;
		
		names.push_back(name);
		blobs.push_back(item);
	}
	
	if (blobs.length == 0) return;
	
	const f32 camera_zoom = camera.targetDistance;

	Vec2f draw_pos = blob.getScreenPos() + Vec2f(0, -80 * camera_zoom);

	Vec2f pane_padding = Vec2f(8, 8);
	Vec2f icon_size = Vec2f(32, 32);

	const f32 pane_width = blobs.length * icon_size.x + 2 * pane_padding.x;
	const f32 pane_height = icon_size.y + 2 * pane_padding.y;

	Vec2f tl = draw_pos - Vec2f(pane_width / 2, pane_height);
	Vec2f br = draw_pos + Vec2f(pane_width / 2, 0);

	GUI::DrawButtonPressed(tl, br);

	draw_pos.x = tl.x + pane_padding.x - icon_size.y;
	draw_pos.y = tl.y + pane_padding.y;

	for (u16 i = 0; i < blobs.length; i++)
	{
		CBlob@ item = blobs[i];
		
		draw_pos.x += item.inventoryFrameDimension.x * 2;
		GUI::DrawIconByName("$scroll_"+names[i]+"$", draw_pos);
	}
}
