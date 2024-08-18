
void onRender(CSprite@ this)
{	
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	CBlob@ gun = blob.getCarriedBlob();
	if (gun !is null)
	{
		if (gun.hasTag("gun"))
		{
			CHUD@ hud = getHUD();

			hud.SetCursorImage("ArcherCursor.png", Vec2f(32, 32));
			hud.SetCursorOffset(Vec2f(-32, -32));
			hud.SetCursorFrame(gun.get_u8("frame"));
			hud.ShowCursor();
		}
	}
}
