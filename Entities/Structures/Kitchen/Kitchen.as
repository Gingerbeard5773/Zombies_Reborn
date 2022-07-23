// Kitchen

#include "Requirements.as";
#include "FireParticle.as";
#include "Zombie_Translation.as";

const u16 craft_time_seconds = 30;
const Vec2f craft_menu_size(4, 1);

CraftItem@[] items;

void onInit(CBlob@ this)
{
	this.inventoryButtonPos = Vec2f(-8.0f, 0.0f);
	this.Tag("builder always hit");
	this.set_TileType("background tile", CMap::tile_castle_back);
	
	this.getShape().getConsts().mapCollisions = false;

	this.getCurrentScript().tickFrequency = 30; //once a second
	
	this.addCommandID("set");

	this.set_u8("crafting", 0);
	this.set_u16("craft_time", craft_time_seconds);

	this.SetLight(false);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	/*
	{
		CBitStream requirements;
		AddRequirement(requirements, "blob", "grain", "Grain", 1);
		//AddRequirement(requirements, "blob", "builder", "Builder", 1);
		addFoodItem(this, "Cake", 5, "A cake made of a builder corpse.", 20, 1, @requirements);
	}
	{
		CBitStream requirements;
		AddRequirement(requirements, "blob", "grain", "Grain", 1);
		AddRequirement(requirements, "blob", "trader", "Russian", 1);
		addFoodItem(this, "Russian Burger", 6, "A hamburger made of a veiny old person.", 30, 1, @requirements);
	}*/
	
	addRecipes();
}

void onReload(CBlob@ this) //for dev
{
	addRecipes();
}

void addRecipes()
{
	if (items.length > 0) return;
	
	{
		CraftItem i("bread", 1, ZombieDesc::bread, 4);
		AddRequirement(i.reqs, "blob", "mat_flour", "Flour", 20);
		items.push_back(i);
	}
	{
		CraftItem i("cake", 1, ZombieDesc::cake, 5);
		AddRequirement(i.reqs, "blob", "mat_flour", "Flour", 15);
		AddRequirement(i.reqs, "blob", "egg", "Egg", 1);
		items.push_back(i);
	}
	{
		CraftItem i("cookedfish", 1, ZombieDesc::cooked_fish, 1);
		AddRequirement(i.reqs, "blob", "fishy", "Fish", 1);
		items.push_back(i);
	}
	{
		CraftItem i("cookedsteak", 1, ZombieDesc::cooked_steak, 0);
		AddRequirement(i.reqs, "blob", "steak", "Steak", 1);
		items.push_back(i);
	}
	
	for (u8 i = 0; i < items.length; i++)
	{
		AddIconToken("$craft_icon" + i + "$", "Food.png", Vec2f(16, 16), items[i].icon);
	}
}

shared class CraftItem
{
	string resultname;
	u32 resultcount;
	u8 icon;
	string title;
	CBitStream reqs;

	CraftItem(const string resultname, const u32 resultcount, const string title, const u8 icon)
	{
		this.resultname = resultname;
		this.resultcount = resultcount;
		this.title = title;
		this.icon = icon;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!isInventoryAccessible(this, caller)) return;
	
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton("$craft_icon"+this.get_u8("crafting")+"$", Vec2f(4,0), this, CraftMenu, "Set Recipe");
}

void CraftMenu(CBlob@ this, CBlob@ caller)
{
	if (caller.isMyPlayer())
	{
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, craft_menu_size, "Recipes");
		if (menu !is null)
		{
			for (u8 i = 0; i < items.length; i++)
			{
				CraftItem@ item = items[i];

				CBitStream pack;
				pack.write_u8(i);
				
				const bool isSelected = this.get_u8("crafting") == i;
				const string food_name = item.title.split("\n")[0];

				const string text = (isSelected ? "Current" : "Set") + " Recipe: " + food_name;

				CGridButton@ butt = menu.AddButton("$craft_icon" + i + "$", text, this.getCommandID("set"), pack);
				butt.hoverText = item.title + "\n\n" + getButtonRequirementsText(item.reqs, false);
				butt.SetEnabled(!isSelected);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("set"))
	{
		this.set_u8("crafting", params.read_u8());
	}
}

void onTick(CBlob@ this)
{
	CraftItem@ item = items[this.get_u8("crafting")];
	CInventory@ inv = this.getInventory();

	CBitStream missing;
	if (hasRequirements(inv, item.reqs, missing))
	{
		this.SetLight(true);
		
		const u16 craft_time = this.get_u16("craft_time");
		this.set_u16("craft_time", Maths::Max(craft_time-1, 0));
		if (craft_time <= 0)
		{
			if (isServer())
			{
				CBlob@ mat = server_CreateBlob(item.resultname, this.getTeamNum(), this.getPosition());
				mat.server_SetQuantity(item.resultcount);

				server_TakeRequirements(inv, item.reqs);
			}

			if (isClient())
			{
				this.getSprite().PlaySound("Cooked.ogg");
			}
			
			this.set_u16("craft_time", craft_time_seconds - 1);
		}
	}
	else
	{
		this.SetLight(false);
		this.set_u16("craft_time", craft_time_seconds);
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this);
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	this.getConsts().accurateLighting = true;
	this.getCurrentScript().tickFrequency = 15;
	this.SetEmitSound("CampfireSound.ogg");

	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 40, 32);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		int[] frames = { 3, 4, 5 };
		anim.AddFrames(frames);
		front.SetRelativeZ(500);
	}
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16);
	if (fire !is null)
	{
		Animation@ anim = fire.addAnimation("fire", 6, true);
		int[] frames = { 1, 2, 3 };
		anim.AddFrames(frames);
		fire.SetRelativeZ(1);
		fire.SetOffset(Vec2f(-9, 7));
		fire.SetVisible(false);
	}
	CSpriteLayer@ fire_bg = this.addSpriteLayer("fire_bg", this.getFilename(), 8, 8);
	if (fire_bg !is null)
	{
		Animation@ anim = fire_bg.addAnimation("default", 0, false);
		anim.AddFrame(120);
		fire_bg.SetOffset(Vec2f(-7, 9));
		fire_bg.SetVisible(false);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ fire_bg = this.getSpriteLayer("fire_bg");
	CSpriteLayer@ fire = this.getSpriteLayer("fire_animation_large");
	if (blob.get_u16("craft_time") < craft_time_seconds)
	{
		this.SetEmitSoundPaused(false);
		fire.SetVisible(true);
		fire_bg.SetVisible(true);
		makeSmokeParticle(blob.getPosition() + Vec2f(7,-15));
	}
	else
	{
		if (!this.getEmitSoundPaused())
			this.SetEmitSoundPaused(true);
			
		fire.SetVisible(false);
		fire_bg.SetVisible(false);
	}
}

/*void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;
	
	CCamera@ camera = getCamera();
	if (camera is null) return;
		
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	const bool mouseOnBlob = (mouseWorld - pos).getLength() < renderRadius;
	if (mouseOnBlob && getHUD().hasButtons() && !getHUD().hasMenus())
	{
		const u16 craft_time = blob.get_u16("craft_time");
		if (craft_time >= craft_time_seconds - 1) return;
		
		const f32 camFactor = camera.targetDistance;
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(pos);

		const f32 hwidth = 50 * camFactor;
		const f32 hheight = 10 * camFactor;

		pos2d.y -= 40 * camFactor;
		const f32 padding = 4.0f * camFactor;
		const f32 shift = 15.0f;
		const f32 progress = (1.1f - float(craft_time) / float(craft_time_seconds))*(hwidth*2-(13* camFactor)); //13 is a magic number used to perfectly align progress
		
		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
				      Vec2f(pos2d.x + hwidth - padding, pos2d.y + hheight - padding),
				      SColor(175,200,207,197)); //draw capture bar background
		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
					  Vec2f((pos2d.x - hwidth + padding) + progress, pos2d.y + hheight - padding),
					  SColor(255, 60, 255, 30));
	}
}*/
