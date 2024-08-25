//Gingerbeard @ July 31, 2024
shared class CraftItem
{
	string result_name;      //name of blob to be produced
	string title;            //description
	u32 result_count;        //amount of blobs to produce
	u16 seconds_to_produce;  //amount of seconds required to produce
	u8 icon_frame;
	CBitStream reqs;

	CraftItem(const string&in result_name, const string&in title, const u8&in icon_frame, const u16&in seconds_to_produce, const u32&in result_count = 1)
	{
		this.result_name = result_name;
		this.result_count = result_count;
		this.seconds_to_produce = seconds_to_produce;
		this.icon_frame = icon_frame;
		this.title = title;
	}
}

shared class Craft
{
	u8 selected;
	u16 time;
	bool can_craft;
	Vec2f menu_size;
	Vec2f button_offset;
	string produce_sound;
	string icon_image;
	CraftItem@[] items;

	Craft()
	{
		selected = 0;
		time = 0;
		can_craft = true;
		menu_size = Vec2f(1, 1);
		button_offset = Vec2f_zero;
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
