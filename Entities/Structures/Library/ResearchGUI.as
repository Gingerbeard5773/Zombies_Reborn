// Research GUI

#include "ResearchTechCommon.as";
#include "Requirements.as";
#include "Zombie_Translation.as";

const f32 buttonsize = 50.0f;
const f32 halfbuttonsize = buttonsize*0.5f;
const f32 quarterbuttonsize = halfbuttonsize*0.5f;
Vec2f size(850, 600);
Vec2f icon_size(22, 22);

SColor color_grey(0xff42484b);
SColor color_dark_green(0xff33660d);
SColor color_red(0xff660d0d);
SColor color_light_green(0xffb0dd35);
SColor color_yellow(0xffffc64b);

void onTick(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("show research")) return;

	Vec2f pos2d;
	Vec2f origin;
	getOrigin(pos2d, origin);

	Vec2f mouse = getControls().getMouseScreenPos();
	
	ResearchTech@ researched;
	blob.get("researching", @researched);

	ResearchTech@[]@ TechTree = getTechTree();
	for (u8 i = 0; i < TechTree.length; i++)
	{
		ResearchTech@ tech = TechTree[i];
		if (tech is null) continue;
		
		const bool duplicate = tech.isResearching() && researched is null;
		
		CBitStream missing;
		if (hasRequirements(localBlob.getInventory(), tech.requirements, missing) || duplicate)
		{
			Vec2f buttonUL, buttonLR;
			getButtonFromTech(tech, origin, buttonUL, buttonLR);

			const bool mouseHover = (mouse.x > buttonUL.x && mouse.x < buttonLR.x && mouse.y > buttonUL.y && mouse.y < buttonLR.y);
			if (mouseHover && localBlob.isKeyJustPressed(key_action1) && researched is null && !tech.isUnlocked() && tech.available)
			{
				Sound::Play(duplicate ? "Switch.ogg" : "/ChaChing.ogg");
				CBitStream params;
				params.write_u8(tech.index);
				blob.SendCommand(blob.getCommandID("server_research"), params);
			}
		}
	}
}

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	CBlob@ blob = this.getBlob();
	
	ShowResearchProgress(blob, localBlob);

	if (localBlob is null || localBlob.isKeyPressed(key_inventory) ||
		localBlob.isKeyJustPressed(key_left) || localBlob.isKeyJustPressed(key_right) || localBlob.isKeyJustPressed(key_up) ||
		localBlob.isKeyJustPressed(key_down) || localBlob.isKeyJustPressed(key_action2) || localBlob.isKeyJustPressed(key_action3))
	{
		blob.Untag("show research");
		getHUD().menuState = 0;
		return;
	}

	if (!blob.hasTag("show research")) return;

	CHUD@ hud = getHUD();
	hud.menuState = 1;
	hud.disableButtonsForATick = true; // no buttons while drawing this

	Vec2f pos2d;
	Vec2f origin;
	getOrigin(pos2d, origin);

	Vec2f mouse = getControls().getMouseScreenPos();

	Vec2f upperleft(pos2d.x-size.x*0.5f, pos2d.y-size.y*0.5f);
	Vec2f lowerright(pos2d.x+size.x*0.5f, pos2d.y+size.y*0.5f);
	
	ResearchTech@ researched;
	blob.get("researching", @researched);

	GUI::DrawRectangle(upperleft, lowerright);
	GUI::SetFont("menu");

	Vec2f iconDim;
	GUI::GetIconDimensions("$TECHNOLOGY_HEADER$", iconDim);
	GUI::DrawIconByName("$TECHNOLOGY_HEADER$", Vec2f(pos2d.x - iconDim.x, pos2d.y - size.y*0.5f - iconDim.y));

	ResearchTech@[]@ TechTree = getTechTree();
	for (u8 i = 0; i < TechTree.length; i++)
	{
		ResearchTech@ tech = TechTree[i];
		if (tech is null) continue;

		Vec2f buttonUL, buttonLR;
		getButtonFromTech(tech, origin, buttonUL, buttonLR);

		const bool mouseHover = (mouse.x > buttonUL.x && mouse.x < buttonLR.x && mouse.y > buttonUL.y && mouse.y < buttonLR.y);

		for (u8 i = 0; i < tech.connections.length; i++)
		{
			ResearchTech@ next_tech = tech.connections[i];
			if (next_tech is null) continue;

			Vec2f nextButtonUL, nextButtonLR;
			getButtonFromTech(next_tech, origin, nextButtonUL, nextButtonLR);

			Vec2f offset(halfbuttonsize, halfbuttonsize);
			Vec2f a, b;
			getArrowPositions(buttonUL + offset, nextButtonUL + offset, a, b);

			const bool researching = next_tech.isResearching();
			if (!tech.isUnlocked())
			{
				GUI::DrawArrow2D(a, b, color_grey);
			}
			else if (next_tech.isUnlocked())
			{
				GUI::DrawArrow2D(a, b, color_dark_green);
			}
			else if (researching)
			{
				Vec2f abNorm = b-a;
				f32 abLen = abNorm.Normalize();
				Vec2f progress = a + abNorm * abLen * next_tech.getPercent();

				GUI::DrawArrow2D(progress, b, next_tech.paused ? color_red : color_light_green);
				GUI::DrawArrow2D(a, progress, color_dark_green);
			}
			else
			{
				GUI::DrawArrow2D(a, b, color_yellow);
			}
		}
		
		if (tech.isResearching() && researched !is null && researched is tech)
			GUI::DrawFramedPane(buttonUL - Vec2f(4, 4), buttonLR + Vec2f(4, 4));

		DrawButton(blob, localBlob, tech, researched, buttonUL, buttonLR, mouseHover);
	}
	
	Vec2f progress_bar_pos = pos2d;
	progress_bar_pos.y += size.y*0.5f;
	//progress_bar.y -= 10.0f;
	DrawProgressBar(blob, progress_bar_pos, researched, size.x * 0.3f);
	
	if (!drawtext.isEmpty())
	{
		GUI::SetFont("menu");

		Vec2f dim;
		GUI::GetTextDimensions(drawtext, dim);
		dim.x = Maths::Min(dim.x, 200.0f);
		dim += Vec2f(4, 4); //margin
		Vec2f buttonpos = drawtextpos + Vec2f(halfbuttonsize, halfbuttonsize);
		const int top = buttonpos.y + dim.y + 16 + halfbuttonsize;
		Vec2f upperleft(buttonpos.x - dim.x / 2, top - dim.y);
		Vec2f lowerright(buttonpos.x + dim.x / 2, top - Maths::Min(int(2 * dim.y), 250));

		GUI::DrawText(drawtext, upperleft, lowerright, color_black, false, false, true);
		drawtext = "";
	}
}

void ShowResearchProgress(CBlob@ blob, CBlob@ localBlob)
{
	if (localBlob is null) return;

	CCamera@ camera = getCamera();
	if (camera is null) return;
	
	if (!localBlob.isKeyPressed(key_use) || getHUD().hasMenus()) return;
	
	ResearchTech@ researched;
	if (!blob.get("researching", @researched) || researched is null) return;

	Vec2f pos = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	const bool mouseOnBlob = (mouseWorld - pos).getLength() < renderRadius;
	if (!mouseOnBlob) return;

	const f32 camFactor = camera.targetDistance;
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(pos);
	pos2d.y -= 40 * camFactor;
	
	const f32 width = 70 * camFactor;

	DrawProgressBar(blob, pos2d, researched, width);

	GUI::DrawIcon("UpgradeIcons.png", researched.index, icon_size, pos2d - icon_size, 1.0f, blob.getTeamNum());
}

string drawtext;
Vec2f drawtextpos;

void getOrigin(Vec2f&out pos2d, Vec2f&out origin)
{
	pos2d = getDriver().getScreenCenterPos();
	pos2d.y += 20.0f;
	origin = pos2d;
	origin.y -= size.y*0.5f - 60.0f;
}

void getButtonFromTech(ResearchTech@ tech, Vec2f center, Vec2f &out ul, Vec2f &out lr)
{
	ul = center + tech.offset*quarterbuttonsize - Vec2f(halfbuttonsize, halfbuttonsize);
	lr.x = ul.x + buttonsize;
	lr.y = ul.y + buttonsize;
}

void getArrowPositions(Vec2f&in center1, Vec2f&in center2, Vec2f&out point1, Vec2f&out point2)
{
    Vec2f direction = center2 - center1;

    if (Maths::Abs(direction.x) > Maths::Abs(direction.y))
    {
        if (direction.x > 0)
		{
            point1 = Vec2f(center1.x + halfbuttonsize, center1.y);
			point2 = Vec2f(center2.x - halfbuttonsize, center2.y);
		}
        else
		{
            point1 = Vec2f(center1.x - halfbuttonsize, center1.y);
			point2 = Vec2f(center2.x + halfbuttonsize, center2.y);
		}
    }
    else
    {
        if (direction.y > 0)
		{
            point1 = Vec2f(center1.x, center1.y + halfbuttonsize);
			point2 = Vec2f(center2.x, center2.y - halfbuttonsize);
		}
        else
		{
            point1 = Vec2f(center1.x, center1.y - halfbuttonsize);
			point2 = Vec2f(center2.x, center2.y + halfbuttonsize);
		}
    }
}

void DrawButton(CBlob@ blob, CBlob@ localBlob, ResearchTech@ tech, ResearchTech@ researched, Vec2f buttonUL, Vec2f buttonLR, const bool mouseHover)
{
	string suffix;
	if (tech.isUnlocked())
	{
		suffix = "\n\n" +"$GREEN$"+Translate::Completed+"$GREEN$";
		GUI::DrawButtonPressed(buttonUL, buttonLR);
		GUI::DrawRectangle(buttonUL + Vec2f(5, 5), buttonLR - Vec2f(5, 5), SColor(100, 127, 255, 20));
	}
	else if (!tech.available)
	{
		GUI::DrawButtonPressed(buttonUL, buttonLR);
	}
	else
	{
		((mouseHover && researched is null) || (tech.isResearching() && researched is tech)) ? GUI::DrawButtonHover(buttonUL, buttonLR) : GUI::DrawButton(buttonUL, buttonLR);
	}

	if (mouseHover)
	{
		string research_time = "";
		if (tech.isResearching())
		{
			suffix = ("\n\n$GREEN$"+Translate::Researching+"$GREEN$").replace("{PERCENT}", Maths::Round(tech.getPercent()*100.0f)+"%");
			if (tech.paused)
			{
				suffix = ("\n\n$RED$"+Translate::Paused+"$RED$").replace("{PERCENT}",  Maths::Round(tech.getPercent()*100.0f)+"%");
				if (researched is null)
					suffix += "\nClick to resume";
			}
		}
		else if (tech.time <= 0)
		{
			CBitStream missing;
			if (hasRequirements(localBlob.getInventory(), tech.requirements, missing))
			{
				suffix = "\n\n" + getButtonRequirementsText(tech.requirements, false);
			}
			else
			{
				suffix = "\n\n" + getButtonRequirementsText(missing, true);
			}
			
			if (!tech.available)
			{
				suffix += "\n$RED$"+Translate::RequiresTech+"$RED$\n";
			}
			
			f32 time = tech.time_to_unlock / f32(60 * getRules().daycycle_speed);
			time = Maths::Ceil(time * 10.0f) / 10.0f;
			research_time = Translate::ResearchTime.replace("{TIME}", time+"")+"\n";
		}

		drawtext = tech.description + suffix + "\n" + research_time;
		drawtextpos = buttonUL;
	}

	GUI::DrawIcon("UpgradeIcons.png", tech.index, icon_size, buttonUL + Vec2f(3.0f, 3.0f), 1.0f, blob.getTeamNum());
}

f32 old_progress = 0.0f;

void DrawProgressBar(CBlob@ blob, Vec2f&in drawpos, ResearchTech@ researched, const f32&in width)
{
	if (researched is null)
	{
		old_progress = 0.0f;
		return;
	}

	const f32 height = 10;
	
	Vec2f tl(drawpos.x - width, drawpos.y - height);
	Vec2f br(drawpos.x + width, drawpos.y + height);
	
	GUI::DrawPane(tl, br, SColor(255, 200, 207, 197));
	
	const f32 progress = researched.getPercent();

    old_progress = Maths::Lerp(old_progress, progress, 0.1f);

	br = Vec2f(tl.x + (br.x - tl.x) * old_progress, br.y);
	if (br.x - 10.0f <= tl.x) return;

	GUI::DrawPane(tl, br, color_light_green);
}
