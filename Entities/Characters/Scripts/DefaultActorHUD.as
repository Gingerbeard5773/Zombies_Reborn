//default actor hud
// a bar with hearts in the bottom left, bottom right free for actor specific stuff

#include "ActorHUDStartPos.as";

void renderBackBar(Vec2f origin, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 64; step += 64.0f * scale)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(step * scale, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(width - 128 * scale, 0), scale);
}

void renderFrontStone(Vec2f farside, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 16.0f * scale * 2; step += 16.0f * scale * 2)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-step * scale - 32 * scale, 0), scale);
	}

	if (width > 16)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-width, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), farside + Vec2f(-width - 32 * scale, 0), scale);
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), farside, scale);
}

void renderHPBar(CBlob@ blob, Vec2f origin)
{
	const string heartFile = "GUI/HeartNBubble.png";
	const u8 segmentWidth = 32;
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-segmentWidth, 0));
	int HPs = 0;
	const f32 initialHealth = blob.getInitialHealth();
	const f32 currentHealth = blob.getHealth();
	const f32 extraHealth = currentHealth - initialHealth;

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

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();

	if (blob is null)
		return;

	Vec2f dim = Vec2f(402, 64);
	Vec2f ul(getHUDX() - dim.x / 2.0f, getHUDY() - dim.y + 12);
	Vec2f lr(ul.x + dim.x, ul.y + dim.y);
	//GUI::DrawPane(ul, lr);
	renderBackBar(ul, dim.x, 1.0f);
	u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
	f32 width = bar_width_in_slots * 40.0f;

	// additional space for drawing resupply icon
	u32 offset = (shouldRenderResupplyIndicator(blob) ? 80 : 40);
	u32 width_offset = (shouldRenderResupplyIndicator(blob) ? 1 * 40.0f : 0);

	renderFrontStone(ul + Vec2f(dim.x + offset, 0), width + width_offset, 1.0f);
	renderHPBar(blob, ul);
	//GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(128,32), topLeft);
}
