
void onRender(CSprite@ this)
{	
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	CBlob@ carried = blob.getCarriedBlob();
	if (carried is null) return;

	if (carried.hasTag("gun"))
	{
		CHUD@ hud = getHUD();

		hud.SetCursorImage("ArcherCursor.png", Vec2f(32, 32));
		hud.SetCursorOffset(Vec2f(-32, -32));
		hud.SetCursorFrame(carried.get_u8("frame"));
		hud.ShowCursor();
	}
}
