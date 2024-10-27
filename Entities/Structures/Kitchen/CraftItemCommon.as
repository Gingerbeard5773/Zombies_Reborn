//Gingerbeard @ July 31, 2024

funcdef void onProduceItemHandle(CBlob@, CBlob@, Craft@);

void addOnProduceItem(CBlob@ this, onProduceItemHandle@ handle) { this.set("onProduceItem handle", @handle); }

namespace ItemType
{
	enum type
	{
		nothing = 0,
		normal,
		material
	}
}

shared class CraftItem
{
	string result_name;      //name of blob to be produced
	string title;            //description
	u32 result_count;        //amount of blobs to produce
	u16 seconds_to_produce;  //amount of seconds required to produce
	u8 icon_frame;           //frame to display
	u8 type;                 //type of item to produce
	CBitStream reqs;

	CraftItem(const string&in result_name, const string&in title, const u8&in icon_frame, const u16&in seconds_to_produce, const u32&in result_count = 1, const u8&in type = ItemType::normal)
	{
		this.result_name = result_name;
		this.result_count = result_count;
		this.seconds_to_produce = seconds_to_produce;
		this.icon_frame = icon_frame;
		this.title = title;
		this.type = type;
	}
}

shared class Craft
{
	u8 selected;             //current selected index of our craft items
	u16 time;                //current crafting time
	bool can_craft;          //dictates if we can even make anything at all
	Vec2f menu_size;         //how big the craft selection menu is
	Vec2f button_offset;     //craft menu button offset
	string produce_sound;    //sound to make when we make an item
	string icon_image;       //png file name to use for craft item icons
	f32 time_modifier;       //percentage to increase or decrease the time to produce
	CraftItem@[] items;

	Craft()
	{
		selected = 0;
		time = 0;
		can_craft = true;
		menu_size = Vec2f(1, 1);
		button_offset = Vec2f_zero;
		time_modifier = 1.0f;
	}
	
	void addItem(CBlob@ blob, CraftItem@ item)
	{
		AddIconToken("$"+blob.getName()+"_craft_icon_"+items.length+"$", icon_image, Vec2f(16, 16), item.icon_frame);
		items.push_back(item);
	}
}

Craft@ getCraft(CBlob@ this)
{
	Craft@ craft;
	this.get("Craft", @craft); 
	return craft;
}
