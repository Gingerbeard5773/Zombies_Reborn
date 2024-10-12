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
