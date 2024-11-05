//Gingerbeard @ October 1st, 2024

namespace Product
{
	enum type
	{
		normal = 0,
		crate,
		seed,
		scroll
	}
}

shared class ProductionItem
{
	string blob_name;         //name of the blob to create
	string name;              //visual name / inventory name
	string icon_name;         //name of the icon to display
	u8 maximum_produced;      //maximum blob amount that can be on the map at one time
	u32 seconds_to_produce;   //seconds it takes to create

	u8 product_type;          //determines what the blob will spawn as (currently supports crates and seeds)
	u8 crate_frame_index;     //crate icon index
	
	u32 next_time_to_produce; //next game time we can produce something
	u16[] produced;           //blob netids of items we have produced and are still on the map
	
	ProductionItem(const string&in blob_name, const string&in name, string&in icon_name, const u32&in seconds_to_produce, const u8&in maximum_produced, const u8&in product_type)
	{
		this.blob_name = blob_name;
		this.name = getTranslatedString(name);
		this.seconds_to_produce = seconds_to_produce;
		this.maximum_produced = maximum_produced;
		this.product_type = product_type;
		
		if (icon_name.isEmpty())
			icon_name = "$"+blob_name+"$";
		this.icon_name = icon_name;
	}

	ProductionItem(ProductionItem@ other)
	{
		this.blob_name = other.blob_name;
		this.name = other.name;
		this.seconds_to_produce = other.seconds_to_produce;
		this.maximum_produced = other.maximum_produced;
		this.product_type = other.product_type;
		this.icon_name = other.icon_name;
		this.crate_frame_index = other.crate_frame_index;
	}
}

shared class Production
{
	string name;
	u8 frame;
	CBitStream reqs;

	ProductionItem@[] production_items;
	
	Production(const string&in name, const u8&in frame)
	{
		this.name = name;
		this.frame = frame;
	}

	Production(Production@ other)
	{
		this.name = other.name;
		this.frame = other.frame;
		this.reqs = other.reqs;
		for (u8 i = 0; i < other.production_items.length; i++)
		{
			ProductionItem item(other.production_items[i]);
			production_items.push_back(item);
		}
	}

	void ResetProduction()
	{
		for (u8 i = 0; i < production_items.length; i++)
		{
			ProductionItem@ item = production_items[i];
			item.next_time_to_produce = getGameTime() + item.seconds_to_produce*30;
		}
	}

	bool isProducing()
	{
		for (u8 i = 0; i < production_items.length; i++)
		{
			if (production_items[i].next_time_to_produce > getGameTime()) return true;
		}
		return false;
	}

	void addProductionItem(const string&in blob_name, const string&in name, const string&in icon_name,
                           const u32&in seconds_to_produce, const u8&in maximum_produced, const u8&in product_type = Product::normal)
	{
		ProductionItem item(blob_name, name, icon_name, seconds_to_produce, maximum_produced, product_type);
		production_items.push_back(item);
	}
}
