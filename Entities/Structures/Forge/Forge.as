
#include "Requirements.as"
#include "CraftItemCommon.as"
#include "FireParticle.as"
#include "Zombie_Translation.as"
#include "Zombie_TechnologyCommon.as"

const string fuel_prop = "fuel_level";
const int max_fuel = 500;

const string[] fuel_names = {"mat_coal", "mat_wood"};
const string[] fuel_icons = {"mat_coal_icon", "mat_wood"};
const int[] fuel_strength = { 3, 1 };

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.inventoryButtonPos = Vec2f(11.5f, 14.0f);

	this.SetLight(false);
	this.SetLightRadius(96.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	this.getCurrentScript().tickFrequency = 30; //once a second
	
	AddIconToken("$mat_coal$", "MaterialCoal.png", Vec2f(16, 16), 3);
	
	this.Tag("builder always hit");
	this.addCommandID("server_add_fuel");
	
	this.set_Vec2f("pull_items_button_offset", Vec2f(-5, -5));
	
	string[] pull_names = { "mat_iron", "mat_coal" };
	this.set("pull_items", pull_names);

	addOnProduceItem(this, @onProduceItem);

	Craft craft();
	craft.menu_size = Vec2f(3, 1);
	craft.button_offset = Vec2f(5.8, -5);
	craft.produce_sound = "Anvil.ogg";
	craft.icon_image = "ForgeIcons.png";
	this.set("Craft", @craft); 
	
	{
		CraftItem i("mat_ironingot", Translate::IronIngot, 0, 10);
		AddRequirement(i.reqs, "blob", "mat_iron", "Iron Ore", 15);
		craft.addItem(this, i);
	}
	{
		CraftItem i("mat_coal", Translate::CharCoal, 2, 10, 10, ItemType::material);
		AddRequirement(i.reqs, "blob", "mat_wood", "Wood", 25);
		craft.addItem(this, i);
	}
	{
		CraftItem i("mat_steelingot", Translate::SteelIngot, 1, 20);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 3);
		AddRequirement(i.reqs, "blob", "mat_coal", "Coal", 25);
		craft.addItem(this, i);
	}
}

void onTick(CBlob@ this)
{
	Craft@ craft = getCraft(this);
	if (craft is null) return;

	this.SetLight(craft.time > 0);
	
	craft.can_craft = false;
	craft.time_modifier = getTimeModifier();

	const s16 fuel = this.get_s16(fuel_prop);
	if (fuel > 0)
	{
		craft.can_craft = true; //start production!
		if (craft.time > 0 && isServer())
		{
			this.set_s16(fuel_prop, fuel - 1);
			this.Sync(fuel_prop, true);
		}
	}
}

f32 getTimeModifier()
{
	f32 time_modifier = 1.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Metallurgy))    time_modifier -= 0.15f;
	if (hasTech(TechTree, Tech::MetallurgyII))  time_modifier -= 0.10f;
	if (hasTech(TechTree, Tech::MetallurgyIII)) time_modifier -= 0.10f;
	if (hasTech(TechTree, Tech::MetallurgyIV))  time_modifier -= 0.15f;
	
	return time_modifier;
}

f32 getRefinementPercent()
{
	f32 percent = 0.0f;
	Technology@[]@ TechTree = getTechTree();
	if (hasTech(TechTree, Tech::Refinement))    percent += 0.10f;
	if (hasTech(TechTree, Tech::RefinementII))  percent += 0.10f;
	if (hasTech(TechTree, Tech::RefinementIII)) percent += 0.10f;
	if (hasTech(TechTree, Tech::RefinementIV))  percent += 0.10f;
	
	return percent;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.isInventoryAccessible(caller)) return;

	if (this.get_s16(fuel_prop) >= max_fuel) return;

	for (u8 i = 0; i < fuel_names.length; i++)
	{
		const string name = fuel_names[i];
		if (!caller.hasBlob(name, 1)) continue;

		CBitStream params;
		params.write_u8(i);
		CButton@ button = caller.CreateGenericButton("$"+fuel_icons[i]+"$", Vec2f(-5.0f, 5.0f), this, this.getCommandID("server_add_fuel"), Translate::AddFuel, params);
		if (button !is null)
		{
			button.deleteAfterClick = false;
		}
		return;
	}
}

void onProduceItem(CBlob@ this, CBlob@ blob, Craft@ craft)
{
	if (isServer() && blob !is null)
	{
		if (XORRandom(100) < 100 * getRefinementPercent())
		{
			blob.server_SetQuantity(blob.getQuantity() + 1);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_add_fuel") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		const int requestedAmount = Maths::Min(250, max_fuel - this.get_s16(fuel_prop));
		if (requestedAmount <= 0) return;
		
		u8 index;
		if (!params.saferead_u8(index)) return;

		const string fuel_name = fuel_names[index];
		const int fuel_amount = fuel_strength[index];

		CBlob@ carried = caller.getCarriedBlob();
		const int callerQuantity = caller.getInventory().getCount(fuel_name) + (carried !is null && carried.getName() == fuel_name ? carried.getQuantity() : 0);
		const int amountToStore = Maths::Min(requestedAmount, callerQuantity);
		if (amountToStore > 0)
		{
			caller.TakeBlob(fuel_name, amountToStore);
			this.set_s16(fuel_prop, this.get_s16(fuel_prop) + amountToStore*fuel_amount);
			this.Sync(fuel_prop, true);
		}
	}
}

///SPRITE

void onInit(CSprite@ this)
{
	CSpriteLayer@ furnace = this.addSpriteLayer("furnace", "Furnace.png", 17, 11);
	if (furnace !is null)
    {
		furnace.SetOffset(Vec2f(-11.5f, 8.0f));

        Animation@ anim2 = furnace.addAnimation("furnace", 3, true);
		int[] frames = { 1, 2, 3 };
		anim2.AddFrames(frames);
		
		furnace.SetRelativeZ(1);
		furnace.SetVisible(false);
    }
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename(), 56, 40);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		int[] frames = { 3, 4 };
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
		fire.SetOffset(Vec2f(-14, 7));
		fire.SetVisible(false);
	}
	this.SetZ(-50); //background
	this.SetEmitSound("Inferno.ogg");
	this.SetEmitSoundPaused(true);
	
	this.getCurrentScript().tickFrequency = 30; //once a second
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Craft@ craft = getCraft(blob);
	if (craft is null) return;

	CSpriteLayer@ furnace = this.getSpriteLayer("furnace");
	CSpriteLayer@ fire = this.getSpriteLayer("fire_animation_large");
	
	if (craft.time > 0)
	{
		this.SetEmitSoundPaused(false);
		furnace.SetVisible(true);
		fire.SetVisible(true);
		makeSmokeParticle(blob.getPosition() + Vec2f(11,-19));
	}
	else
	{
		this.SetEmitSoundPaused(true);	
		furnace.SetVisible(false);
		fire.SetVisible(false);
	}
}
