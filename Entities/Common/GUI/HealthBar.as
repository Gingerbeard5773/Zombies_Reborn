// draws a health bar on mouse hover

void onRender(CSprite@ this)
{
	if (g_videorecording) return;

	CBlob@ blob = this.getBlob();
	if (blob.isInInventory()) return;
	
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (!mouseOnBlob) return;

	const f32 initialHealth = blob.getInitialHealth();
	if (initialHealth <= 0.0f) return;
	
	const f32 health = blob.getHealth();
	const f32 percent = health / initialHealth;
	if (percent <= 0.0f) return;

	const f32 zoom = getCamera().targetDistance * getDriver().getResolutionScaleFactor();
	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 30 + blob.getHeight() * zoom);
	Vec2f dim = Vec2f(25, 8);
	const f32 widthScaleFactor = Maths::Max(1.0f, percent);
	Vec2f scaledDim = Vec2f(dim.x * widthScaleFactor, dim.y);

	Vec2f tl(pos2d.x - scaledDim.x - 2, pos2d.y - 2);
	Vec2f br(pos2d.x + scaledDim.x + 2, pos2d.y + scaledDim.y + 2);

	Vec2f tl2(pos2d.x - scaledDim.x + 2, pos2d.y + 2);
	Vec2f br2(pos2d.x - scaledDim.x - 2 + percent * 2.0f * dim.x, pos2d.y + scaledDim.y - 2);
	
	GUI::DrawRectangle(tl, br);
	GUI::DrawRectangle(tl2, br2, SColor(0xffac1512));
}

