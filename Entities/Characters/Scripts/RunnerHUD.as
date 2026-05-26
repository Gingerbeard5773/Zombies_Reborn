// Runner HUD for ZF
// Gingerbeard @ Jan 24, 2026

#include "ArcherCommon.as"

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void ManageCursors(CBlob@ this)
{
	CHUD@ hud = getHUD();
	if (hud.hasButtons())
	{
		hud.SetDefaultCursor();
		return;
	}

	const string name = this.getName();
	if (name == "archer" || this.isAttached() && this.isAttachedToPoint("GUNNER"))
	{
		hud.SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32, 32));
		hud.SetCursorOffset(Vec2f(-16, -16) * cl_mouse_scale);
	}
	else if (name == "knight")
	{
		hud.SetCursorImage("Entities/Characters/Knight/KnightCursor.png", Vec2f(32, 32));
		hud.SetCursorOffset(Vec2f(-11, -11) * cl_mouse_scale);
	}
	else if (name == "builder")
	{
		hud.SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
		//hud.SetCursorOffset(Vec2f(0, 0) * cl_mouse_scale);
	}
	else if (name == "wizard")
	{
		hud.SetCursorImage("MagicCursor.png", Vec2f(32, 32));
		hud.SetCursorOffset(Vec2f(-16, -16) * cl_mouse_scale);
	}
	else
	{
		hud.SetDefaultCursor();
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	ManageCursors(blob);

	if (g_videorecording) return;

	Vec2f origin(getScreenWidth() / 3, getScreenHeight() - 40.0f);
	Vec2f tl = origin + Vec2f(0, -14);

	const bool builder = blob.getName() == "builder";
	const f32 builder_margin = (builder ? 30 : 0);

	DrawFrontStone(tl + Vec2f(80, 0), 80 + builder_margin, 1.0f);
	DrawHPBar(blob, tl + Vec2f(-60 - builder_margin, 0));

	if (builder)
	{
		DrawResupplyOnHUD(blob, origin - Vec2f(30, 4));
	}

	DrawClassIcon(blob, origin);

	DrawCoinsOnHUD(blob, origin + Vec2f(40, 0));

	DrawInventoryOnHUD(blob, tl + Vec2f(140, 0));
}

void DrawClassIcon(CBlob@ this, Vec2f origin)
{
	Vec2f drawpos = origin + Vec2f(10, -16);
	const string name = this.getName();
	if (name == "knight")
	{
		const u8 bomb_type = this.get_u8("bomb type");
		u8 frame = 1;
		if (bomb_type == 0)
		{
			frame = 0;
		}
		else if (bomb_type < 255)
		{
			frame = 1 + bomb_type;
		}
		GUI::DrawIcon("KnightIcons.png", frame, Vec2f(16, 32), drawpos, 1.0f, this.getTeamNum());
	}
	else if (name == "archer")
	{
		GUI::DrawIcon("ArcherIcons.png", getArrowType(this), Vec2f(16, 32), drawpos, 1.0f, this.getTeamNum());
	}
	else
	{
		GUI::DrawIcon("BuilderIcons.png", 3, Vec2f(16, 32), drawpos, 1.0f, this.getTeamNum());
	}
}

void DrawBackBar(Vec2f origin, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 64; step += 64.0f * scale)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(step * scale, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(width - 128 * scale, 0), scale);
}

void DrawFrontStone(Vec2f origin, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 16.0f * scale * 2; step += 16.0f * scale * 2)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-step * scale - 32 * scale, 0), scale);
	}

	if (width > 16)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), origin + Vec2f(-width, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-width - 32 * scale, 0), scale);
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin, scale);
}

void DrawHPBar(CBlob@ blob, Vec2f origin)
{
	const string heartFile = "GUI/HeartNBubble.png";
	const u8 segmentWidth = 32;
	const f32 initialHealth = blob.getInitialHealth();
	const f32 currentHealth = blob.getHealth();
	const f32 extraHealth = currentHealth - initialHealth;

	origin.x -= initialHealth * 2 * segmentWidth;

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-segmentWidth, 0));

	int HPs = 0;
	for (f32 step = 0.0f; step < initialHealth; step += 0.5f)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(16, 32), origin + Vec2f(segmentWidth * HPs, 0));
		const f32 health = currentHealth - step;
		if (health > 0)
		{
			Vec2f heartoffset = (Vec2f(2, 10) * 2);
			Vec2f heartpos = origin + Vec2f(segmentWidth * HPs, 0) + heartoffset;

			u8 frame = 1;
			if (health <= 0.125f)      frame = 4;
			else if (health <= 0.25f)  frame = 3;
			else if (health <= 0.375f) frame = 2;

			GUI::DrawIcon(heartFile, frame, Vec2f(12, 12), heartpos);
		}

		HPs++;
	}
	
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f(32 * HPs, 0));
	
	if (extraHealth > 0)
	{
		HPs = 0;
		for (f32 step = 0.0f; step < extraHealth; step += 0.5f)
		{
			const f32 health = extraHealth - step;
			if (health > 0)
			{
				int frameoffset = 5;
				const int layeredHearts = Maths::Floor(HPs / (initialHealth * 2.0f));
				Vec2f heartoffset = (Vec2f(2, 10) * 2) + Vec2f(0, layeredHearts > 0 ? layeredHearts * -10 : 0);
				Vec2f heartpos = origin + Vec2f(segmentWidth * (HPs % (initialHealth * 2.0f)), 0) + heartoffset;

				u8 frame = 1;
				if (health <= 0.125f)      frame = 4;
				else if (health <= 0.25f)  frame = 3;
				else if (health <= 0.375f) frame = 2;

				GUI::DrawIcon(heartFile, frame + frameoffset, Vec2f(12, 12), heartpos);
			}

			HPs++;
		}
	}
}

void DrawInventoryOnHUD(CBlob@ this, Vec2f origin)
{
	SColor col;
	CInventory@ inv = this.getInventory();
	if (inv.getItemsCount() <= 0) return;

	string[] drawn;
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		const string name = inv.getItem(i).getName();
		if (drawn.find(name) == -1) drawn.push_back(name);
	}

	const int width_buffer = 10;
	const int width = (drawn.length * 40) + 10 + width_buffer;
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-32, 0));
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f(width, 0));
	GUI::DrawPane(origin + Vec2f(-10, 6), origin + Vec2f(width + 10, 60));

	drawn.clear();
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		const string name = item.getName();
		if (drawn.find(name) == -1)
		{
			const int quantity = inv.getCount(name);
			drawn.push_back(name);

			Vec2f iconpos = origin + Vec2f((drawn.length - 1) * 40, 6);
			iconpos.x += width_buffer;
			iconpos.x += Maths::Clamp(16 - item.inventoryFrameDimension.x, -item.inventoryFrameDimension.x, item.inventoryFrameDimension.x);
			iconpos.y += Maths::Max(16 - item.inventoryFrameDimension.y, 0);
			GUI::DrawIcon(item.inventoryIconName, item.inventoryIconFrame, item.inventoryFrameDimension, iconpos, 1.0f, item.getTeamNum());

			f32 ratio = float(quantity) / float(item.maxQuantity);
			col = ratio > 0.4f ? SColor(255, 255, 255, 255) :
			      ratio > 0.2f ? SColor(255, 255, 255, 128) :
			      ratio > 0.1f ? SColor(255, 255, 128, 0) : SColor(255, 255, 0, 0);

			GUI::SetFont("menu");
			Vec2f dimensions(0,0);
			string disp = "" + quantity;
			GUI::GetTextDimensions(disp, dimensions);
			GUI::DrawText(disp, origin + Vec2f(14 + width_buffer + (drawn.length - 1) * 40 - dimensions.x/2 , 38), col);
		}
	}
}

void DrawCoinsOnHUD(CBlob@ this, Vec2f origin)
{
	CPlayer@ player = this.getPlayer();
	if (player is null) return;

	GUI::DrawIconByName("$COIN$", origin);
	GUI::SetFont("menu");
	GUI::DrawTextCentered("" + player.getCoins(), origin + Vec2f(15, 32), color_white);
}

void DrawResupplyOnHUD(CBlob@ this, Vec2f origin)
{
	CRules@ rules = getRules();
	if (!rules.exists("builder_mats_time")) return;

	GUI::SetFont("menu");

	const int next_items = rules.get_u32("builder_mats_time");

	string action = (this.getName() == "builder" ? "Go Build" : "Go Fight");
	if (rules.get_u16("day_number") < 2)
	{
		action = "Prepare for Battle";
	}

	const u32 secs = ((next_items - 1 - getGameTime()) / getTicksASecond()) + 1;
	const string units = ((secs != 1) ? " seconds" : " second");

	const string resupply = getTranslatedString("Next resupply in {SEC}{TIMESUFFIX}, {ACTION}!")
	                        .replace("{SEC}", "" + secs)
	                        .replace("{TIMESUFFIX}", getTranslatedString(units))
	                        .replace("{ACTION}", getTranslatedString(action));

	Vec2f dim;
	GUI::GetTextDimensions(resupply, dim);

	Vec2f icon_size = Vec2f(16, 16);

	if (next_items > getGameTime())
	{
		GUI::DrawIcon("Entities/Common/GUI/ResupplyIcon.png", 0, icon_size, origin, 1.0f);
		GUI::DrawTextCentered(secs + "s", origin + Vec2f(14, 36), color_white);

		if (hoverOnResupplyIcon(origin, icon_size))
		{
			GUI::DrawTextCentered(resupply, origin + Vec2f(0, -icon_size.x - 5), color_white);
		}
	}
	else
	{
		GUI::DrawIcon("Entities/Common/GUI/ResupplyIcon.png", 1, icon_size, origin + Vec2f(0, 6), 1.0f);
	}
}

bool hoverOnResupplyIcon(Vec2f icon_pos, Vec2f icon_size)
{
	Vec2f mouse_pos = getControls().getMouseScreenPos();

	return mouse_pos.x > icon_pos.x && mouse_pos.x < icon_pos.x + icon_size.x * 2
		&& mouse_pos.y > icon_pos.y && mouse_pos.y < icon_pos.y + icon_size.y * 2 + 6;
}
