//Sign
//Gingerbeard @ April 15, 2026

const string help_text = "!write [text]";

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.set_string("text", help_text);
}

void onTick(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 30;

	CBlob@ blob = this.getBlob();
	if (blob.get_string("text") != help_text)
	{
		this.SetAnimation("written");
		this.getCurrentScript().tickFrequency = 0;
	}
}

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	if (getHUD().menuState != 0) return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 1.50f;
	const bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

	if (((localBlob.getPosition() - center).Length() < 0.5f * (localBlob.getRadius() + blob.getRadius())) &&
	   (!getHUD().hasButtons()) || (mouseOnBlob))
	{
		Vec2f pos2d = blob.getScreenPos();
		int top = pos2d.y - 2.5f * blob.getHeight() + 0.0f; //y offset
		int left = 0.0f; //x offset
		if (blob.get_string("text").length >= 29) left = 150.0f; //set to side if string is too long
		int margin = 4;
		Vec2f dim;
		const string label = getTranslatedString(blob.get_string("text"))+"\n";
		GUI::SetFont("menu");
		GUI::GetTextDimensions(label , dim);
		dim.x = Maths::Min(dim.x, 200.0f);
		dim.x += margin;
		dim.y += margin;
		top += dim.y;
		Vec2f upperleft(pos2d.x - dim.x / 2 - left, top - Maths::Min(int(2 * dim.y), 250));
		Vec2f lowerright(pos2d.x + dim.x / 2 - left, top - dim.y);
		GUI::DrawText(label, Vec2f(upperleft.x + margin, upperleft.y + margin + margin),
		              Vec2f(upperleft.x + margin + dim.x, upperleft.y + margin + dim.y),
		              SColor(255, 0, 0, 0), false, false, true);
	}
}
