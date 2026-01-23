//Gingerbeard @ October 10, 2024

funcdef void ShopMadeItemHandle(CBlob@, CBlob@, CBlob@, SaleItem@);

void addOnShopMadeItem(CBlob@ this, ShopMadeItemHandle@ handle) { this.set("onShopMadeItem handle", @handle); }

namespace ItemType
{
	enum type
	{
		nothing = 0,
		normal,
		material,
		crate,
		seed,
		scroll,
		coin
	}
}

shared class Shop
{
	string description;
	Vec2f menu_size;
	Vec2f menu_offset;
	Vec2f button_offset;
	u8 button_icon;
	f32 button_enable_radius;
	bool available;

	SaleItem@[] items;
	
	Shop(CBlob@ blob, const string&in description)
	{
		this.description = description;
		this.menu_size = Vec2f_zero;
		this.menu_offset = Vec2f_zero;
		this.button_offset = Vec2f_zero;
		this.button_icon = 25;
		this.button_enable_radius = Maths::Max(blob.getRadius(), (blob.getWidth() + blob.getHeight()) / 2);
		this.available = true;
		
		blob.set("shop", @this);
	}
}

shared class SaleItem
{
	string name;
	string icon_name;
	string blob_name;
	string description;
	
	u8 type;
	u8 crate_frame_index;
	u16 quantity;
	int stock;
	int custom_data;
	Vec2f button_dimensions;
	CBitStream requirements;
	
	SaleItem(SaleItem@[]@ items, const string&in name, const string&in icon_name, const string&in blob_name, const string&in description,
	         const u8&in type = ItemType::normal, const u16&in quantity = 1, const int&in stock = -1)
	{
		this.name = name;
		this.icon_name = icon_name;
		this.blob_name = blob_name;
		this.description = description;
		this.type = type;
		this.crate_frame_index = 0;
		this.quantity = quantity;
		this.stock = stock;
		this.custom_data = 0;
		this.button_dimensions = Vec2f_zero;
		
		items.push_back(@this);
	}
}

void AddRandomItemsToShop(Shop@ shop, SaleItem@[]@ items, Random@ seed, const u8&in amount)
{
	u32 weights_sum = 0;
	for (u8 i = 0; i < items.length; i++)
	{
		weights_sum += items[i].custom_data;
	}
	
	for (u8 a = 0; a < amount; a++)
	{
		SaleItem@ add_item = GetRandomSaleItem(items, weights_sum, seed);
		bool exists = false;
		for (u8 i = 0; i < shop.items.length; i++)
		{
			SaleItem@ item = shop.items[i];
			if (item.blob_name == add_item.blob_name)
			{
				exists = true;
				a--;
			}
		}
		if (!exists) shop.items.push_back(add_item);
	}
}

SaleItem@ GetRandomSaleItem(SaleItem@[]@ items, const u32&in weights_sum, Random@ seed)
{
	const u32 random_weight = seed.NextRanged(weights_sum);
	u32 current_number = 0;

	for (u8 i = 0; i < items.length; i++)
	{
		SaleItem@ item = items[i];
		if (random_weight <= current_number + item.custom_data)
		{
			return item;
		}

		current_number += item.custom_data;
	}

	return null;
}
