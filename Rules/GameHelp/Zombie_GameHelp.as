//Zombie Fortress help prompt

#define CLIENT_ONLY

#include "Zombie_Translation.as";

bool mousePress = false;
u8 page = 0;

const u8 pages = 6;

const int KEY_MISC = getControls().getActionKeyKey(AK_MENU);

void onInit(CRules@ this)
{
	this.set_bool("show_gamehelp", true);
	CFileImage@ image = CFileImage("HelpBackground.png");
	const Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());
	AddIconToken("$HELP$", "HelpBackground.png", imageSize, 0);
}

void onTick(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(KEY_MISC))
	{
		this.set_bool("show_gamehelp", !this.get_bool("show_gamehelp"));
	}
}

void onRender(CRules@ this)
{
	if (!this.get_bool("show_gamehelp")) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	Vec2f center = getDriver().getScreenCenterPos();
	
	Vec2f imageSize;
	GUI::GetIconDimensions("$HELP$", imageSize);
	GUI::DrawIconByName("$HELP$", Vec2f(center.x - imageSize.x, center.y - imageSize.y));
	
	switch(page)
	{
		case 0: page1(imageSize, center); break;
		case 1: page2(imageSize, center); break;
		case 2: page3(imageSize, center); break;
		case 3: page4(imageSize, center); break;
		case 4: page5(imageSize, center); break;
		case 5: page6(imageSize, center); break;
	};
	
	CControls@ controls = getControls();
	const Vec2f mousePos = controls.getMouseScreenPos();
	
	makeExitButton(this, Vec2f(center.x + imageSize.x - 20, center.y - imageSize.y + 20), controls, mousePos);
	
	makePageChangeButton(Vec2f(center.x+22, center.y + imageSize.y + 50), controls, mousePos, true);
	makePageChangeButton(Vec2f(center.x-22, center.y + imageSize.y + 50), controls, mousePos, false);
	
	makeWebsiteLink(Vec2f(center.x+250, center.y + imageSize.y + 30), "Discord", "https://discord.gg/V29BBeba3C");
	makeWebsiteLink(Vec2f(center.x+160, center.y + imageSize.y + 30), "Github", "https://github.com/Gingerbeard5773/Zombies_Reborn");
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered((page+1)+"/"+pages, center+imageSize - Vec2f(30, 25), color_black);
	
	mousePress = controls.mousePressed1; 
}

void makeExitButton(CRules@ this, Vec2f&in pos, CControls@ controls, Vec2f&in mousePos)
{
	Vec2f tl = pos + Vec2f(-20, -20);
	Vec2f br = pos + Vec2f(20, 20);
	
	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);
		
		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			this.set_bool("show_gamehelp", false);
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}
	GUI::DrawIcon("MenuItems", 29, Vec2f(32,32), Vec2f(pos.x-32, pos.y-32), 1.0f);
}

void makePageChangeButton(Vec2f&in pos, CControls@ controls, Vec2f&in mousePos, const bool&in right)
{
	Vec2f tl = pos + Vec2f(-20, -20);
	Vec2f br = pos + Vec2f(20, 20);
	
	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);
		
		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			if (right)
				page = page == pages - 1 ? 0 : page + 1;
			else
				page = page == 0 ? pages - 1 : page - 1;
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}
	GUI::DrawIcon("MenuItems", right ? 22 : 23, Vec2f(32,32), Vec2f(pos.x-32, pos.y-32), 1.0f);
}

void makeWebsiteLink(Vec2f pos, const string&in text, const string&in website)
{
	Vec2f dim;
	GUI::GetTextDimensions(text, dim);

	const f32 width = dim.x + 20;
	const f32 height = 40;
	const Vec2f tl = Vec2f(getScreenWidth() - width - pos.x, pos.y);
	const Vec2f br = Vec2f(getScreenWidth() - pos.x, tl.y + height);

	CControls@ controls = getControls();
	const Vec2f mousePos = controls.getMouseScreenPos();

	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);

		if (controls.mousePressed1 && !mousePress)
		{
			Sound::Play("option");
			OpenWebsite(website);
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}

	GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
}

void drawHeader(const string&in text, const Vec2f&in pos)
{
	GUI::SetFont("big font");
	GUI::DrawTextCentered(text, pos, color_black);
}

void page1(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page1.png", Vec2f(center.x - imageSize.x, center.y - imageSize.y/2));
	
	drawHeader(ZombieDesc::title, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::game_mode, center - Vec2f(0, imageSize.y - 140), color_black);
	//GUI::DrawTextCentered(ZombieDesc::change_page, center - Vec2f(0, imageSize.y - 180), color_black);
}

void page2(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page2.png", Vec2f(center.x - imageSize.x/2, center.y - imageSize.y/3));
	
	drawHeader(ZombieDesc::tips, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::tip_gateways, center - Vec2f(0, imageSize.y - 140), color_black);
}

void page3(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page3.png", Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3));
	
	drawHeader(ZombieDesc::tips, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::tip_zombification, center - Vec2f(0, imageSize.y - 140), color_black);
}

void page4(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page4.png", Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3));
	
	drawHeader(ZombieDesc::tips, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::tip_water_wraith, center - Vec2f(0, imageSize.y - 140), color_black);
}

void page5(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page5.png", Vec2f(center.x - imageSize.x + 100, center.y - imageSize.y/3));
	
	drawHeader(ZombieDesc::tips, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::tip_headshot, center - Vec2f(0, imageSize.y - 140), color_black);
}

void page6(Vec2f&in imageSize, Vec2f&in center)
{
	GUI::DrawIcon("Page6.png", Vec2f(center.x - imageSize.x + 150, center.y - imageSize.y/3));
	
	drawHeader(ZombieDesc::tips, center - Vec2f(0, imageSize.y - 50));
	
	GUI::SetFont("medium font");
	GUI::DrawTextCentered(ZombieDesc::tip_merchant, center - Vec2f(0, imageSize.y - 140), color_black);
}
