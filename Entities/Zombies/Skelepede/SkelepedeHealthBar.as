// draws a health bar on mouse hover

bool rendering = false;

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	
	CBlob@ head = getBlobByNetworkID(blob.get_netid("skelepede_head_netid"));
	if (head is null) return;
	
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob && !rendering)
	{
		//VV right here VV
		const f32 zoom = getCamera().targetDistance * getDriver().getResolutionScaleFactor();
		Vec2f pos2d = getControls().getMouseScreenPos() + Vec2f(0, 30);
		Vec2f dim = Vec2f(24, 8);
		const f32 y = blob.getHeight() * zoom;
		const f32 initialHealth = head.getInitialHealth();
		if (initialHealth > 0.0f)
		{
			const f32 perc = head.getHealth() / initialHealth;
			if (perc >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xffac1512));
				rendering = true;
				return;
			}
		}
	}
	rendering = false;
}
