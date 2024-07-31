#include "CraftItemCommon.as"

//render crafting progress
void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;
	
	CCamera@ camera = getCamera();
	if (camera is null) return;

	CBlob@ blob = this.getBlob();
	Craft@ craft = getCraft(blob);
	if (craft is null || craft.time <= 0) return;
	
	CraftItem@ item = craft.items[craft.selected];

	Vec2f pos = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	const bool mouseOnBlob = (mouseWorld - pos).getLength() < renderRadius;
	if (mouseOnBlob && getHUD().hasButtons() && !getHUD().hasMenus())
	{
		const f32 camFactor = camera.targetDistance;
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(pos);
		pos2d.y -= 40 * camFactor;

		const f32 hwidth = 40 * camFactor;
		const f32 hheight = 10 * camFactor;

		Vec2f upperleft(pos2d.x - hwidth, pos2d.y + hheight - 23.0f);
		Vec2f lowerright(pos2d.x + hwidth, pos2d.y + hheight);

		GUI::DrawProgressBar(upperleft, lowerright, f32(craft.time) / f32(item.seconds_to_produce));

		const string iconName = "$"+blob.getName()+"_craft_icon_"+craft.selected+"$";
		Vec2f iconDim;
		GUI::GetIconDimensions(iconName, iconDim);
		GUI::DrawIconByName(iconName, Vec2f(pos2d.x - iconDim.x, upperleft.y - iconDim.y/2));
	}
}
