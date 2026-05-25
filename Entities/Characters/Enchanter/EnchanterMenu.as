// Enchanter menu

#include "EnchanterCommon.as"
#include "RequirementsCustom.as"

bool mousePress;

void onTick(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null || localBlob.isKeyPressed(key_inventory) ||
		localBlob.isKeyJustPressed(key_left) || localBlob.isKeyJustPressed(key_right) || localBlob.isKeyJustPressed(key_up) ||
		localBlob.isKeyJustPressed(key_down) || localBlob.isKeyJustPressed(key_action2) || localBlob.isKeyJustPressed(key_action3))
	{
		this.getBlob().Untag("assessment_menu");
	}
}

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	CBlob@ blob = this.getBlob();
	if (!blob.hasTag("enchanter_paid"))
	{
		DrawRequirements(blob, localBlob);
	}
	else if (blob.hasTag("assessment_menu"))
	{
		DrawEnchantMenu(blob, localBlob);
	}
	else
	{
		DrawEnchantsCount(blob, localBlob);
	}
}

void DrawEnchantsCount(CBlob@ blob, CBlob@ localBlob)
{
	if (!localBlob.isKeyPressed(key_use) || getHUD().hasMenus()) return;

	if (localBlob.getDistanceTo(blob) > 60.0f) return;

	GUI::SetFont("menu");
	Vec2f text_pos = blob.getScreenPos() + Vec2f(0, 40);
	GUI::DrawTextCentered(Translate("EnchantGUI5").replace("{INPUT}", blob.get_u8("enchants_count")+""), text_pos, color_white);
}

void DrawRequirements(CBlob@ blob, CBlob@ localBlob)
{
	if (!localBlob.isKeyPressed(key_use) || getHUD().hasMenus()) return;

	if (localBlob.getDistanceTo(blob) > 60.0f) return;

	CBitStream@ reqs;
	if (!blob.get("enchanter_requirements", @reqs)) return;

	const string text = getRequirementText(getRequirementBlobs(localBlob), reqs);

	Vec2f dim;
	GUI::SetFont("menu");
	GUI::GetTextDimensions(text, dim);

	dim.x /= 2.0f;

	Vec2f drawpos = blob.getScreenPos() - Vec2f(dim.x * 0.5f, -70.0f);
	Vec2f tl = drawpos;
	Vec2f br = drawpos + dim;

	Vec2f pane_tl = tl - Vec2f(10.0f, 10.0f);
	Vec2f pane_br = br + Vec2f(10.0f, 0.0f);
	GUI::DrawWindow(pane_tl, pane_br);

	GUI::DrawText(text, tl, br, color_black, false, false, false);
	
	GUI::SetFont("medium font");
	Vec2f text_pos = tl - Vec2f(-dim.x * 0.5f, 25.0f);
	GUI::DrawTextCentered(Translate("EnchantGUI2"), text_pos, color_white);
}

void DrawEnchantMenu(CBlob@ blob, CBlob@ localBlob)
{
	AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("ENCHANT");
	if (point is null) return;

	CBlob@ item = point.getOccupied();
	if (item is null) return;

	Enchant@ enchant = getEnchant(blob, item);
	if (enchant is null) return;

	const string text = Translate("EnchantGUI4").replace("{ITEM}", name(enchant.description));

	Vec2f dim;
	GUI::SetFont("menu");
	GUI::GetTextDimensions(text, dim);

	Vec2f drawpos = blob.getScreenPos() - Vec2f(dim.x * 0.5f, -70.0f);
	Vec2f tl = drawpos;
	Vec2f br = drawpos + dim;

	Vec2f pane_tl = tl - Vec2f(10.0f, 10.0f);
	Vec2f pane_br = br + Vec2f(10.0f, 10.0f);
	GUI::DrawWindow(pane_tl, pane_br);

	GUI::DrawText(text, tl, br, color_black, false, false, false);

	GUI::SetFont("medium font");
	Vec2f text_pos0 = tl - Vec2f(-dim.x * 0.5f, 25.0f);
	GUI::DrawTextCentered(Translate("EnchantGUI3"), text_pos0, color_white);

	Vec2f buttonpos_1 = pane_tl - Vec2f(dim.y + 20.0f, 0);
	Vec2f buttonpos_2 = pane_br + Vec2f(0, -dim.y - 20.0f);
	DrawConfirmButton(blob, buttonpos_1, dim.y + 20.0f, false);
	DrawConfirmButton(blob, buttonpos_2, dim.y + 20.0f, true);

	mousePress = getControls().mousePressed1; 
}

void DrawConfirmButton(CBlob@ blob, Vec2f pos, const f32&in size, const bool&in do_enchant)
{
	Vec2f tl = pos;
	Vec2f br(pos.x + size, pos.y + size);

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();
	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);
		if (controls.mousePressed1 && !mousePress)
		{
			blob.Untag("assessment_menu");
			Sound::Play("switch.ogg");

			CBitStream stream;
			stream.write_bool(do_enchant);
			blob.SendCommand(blob.getCommandID("server_enchant_item"), stream);
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}
	
	const f32 scale = (size - 16.0f) / 32.0f;
	Vec2f iconSize = Vec2f(32, 32) * scale;
	Vec2f iconPos = tl + (Vec2f(size, size) - iconSize * 2) * 0.5f;
	GUI::DrawIcon("MenuItems.png", do_enchant ? 28 : 29, Vec2f(32, 32), iconPos, scale);
}
