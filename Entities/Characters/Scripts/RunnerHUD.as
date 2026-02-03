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
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
		return;
	}

	const string name = this.getName();
	if (name == "archer" || this.isAttached() && this.isAttachedToPoint("GUNNER"))
	{
		getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-16, -16) * cl_mouse_scale);
	}
	else if (name == "knight")
	{
		getHUD().SetCursorImage("Entities/Characters/Knight/KnightCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-11, -11) * cl_mouse_scale);
	}
	else
	{
		getHUD().SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	ManageCursors(blob);

	if (g_videorecording) return;

	Vec2f origin(getScreenWidth() / 3, getScreenHeight() - 40.0f);
	Vec2f tl = origin + Vec2f(0, -14);

	DrawFrontStone(tl + Vec2f(80, 0), 80, 1.0f);
	DrawHPBar(blob, tl + Vec2f(-60, 0));

	DrawInventoryOnHUD(blob, tl + Vec2f(140, 0));

	DrawCoinsOnHUD(blob, origin + Vec2f(40, 0));

	DrawClassIcon(blob, origin);
}

void DrawClassIcon(CBlob@ this, Vec2f origin)
{
	Vec2f drawpos = origin + Vec2f(10, -16);
	const string name = this.getName();
	if (name == "knight")
	{
		u8 type = this.get_u8("bomb type");
		u8 frame = 1;
		if (type == 0)
		{
			frame = 0;
		}
		else if (type < 255)
		{
			frame = 1 + type;
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
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-32, 0));
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f((drawn.length * 40) + width_buffer, 0));
	GUI::DrawPane(origin + Vec2f(-10, 6), origin + Vec2f((drawn.length * 40) + 10 + width_buffer, 60));

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
