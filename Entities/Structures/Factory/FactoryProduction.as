//Gingerbeard @ October 1st, 2024
//I wrote up my own production system because the base one is BLOAT GARBAGE.

// set_string "produce sound" to override default production sound
// this.Tag("huffpuff production"); for production effects
// this.set_Vec2f("production offset", Vec2f() ); for changing where blobs appear

#include "FactoryProductionCommon.as";
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "FireParticle.as";

const u32 TICK_FREQUENCY = 30;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = TICK_FREQUENCY;
	
	this.addCommandID("client_produce_item");
	this.addCommandID("client_set_produce_time");
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("can produce")) return;

	Production@ production;
	if (!this.get("production", @production)) return;

	if (isClient())
	{
		if (this.hasTag("huffpuff production") && production.isProducing() && XORRandom(5) == 0)
		{
			Sound::Play("/ProduceSound", this.getPosition());
			makeSmokeParticle(this.getPosition() + Vec2f(0.0f, -this.getRadius() / 2.0f));
		}
	}

	if (isServer())
	{
		for (u8 i = 0; i < production.production_items.length; i++)
		{
			server_ProcessItem(this, production, production.production_items[i], i);
		}
	}
}

void server_ProcessItem(CBlob@ this, Production@ production, ProductionItem@ item, const u8&in index)
{
	//check up on our produced blobs
	const u8 old_produced_amount = item.produced.length;
	for (u8 i = 0; i < item.produced.length; i++)
	{
		CBlob@ produced_item = getBlobByNetworkID(item.produced[i]);
		if (produced_item is null)
		{
			item.produced.erase(i);
			i--;
			continue;
		}
	}
	
	const u8 new_produced_amount = item.produced.length;
	
	//start up again
	if (new_produced_amount < old_produced_amount && old_produced_amount >= item.maximum_produced)
	{
		item.next_time_to_produce = getGameTime() + (item.seconds_to_produce*30) * production.modifier;
		
		CBitStream stream;
		stream.write_u8(index);
		stream.write_u32(item.next_time_to_produce);
		this.SendCommand(this.getCommandID("client_set_produce_time"), stream);
	}

	//make new blobs
	if (new_produced_amount < item.maximum_produced && getGameTime() >= item.next_time_to_produce)
	{
		CBlob@ produced_item = server_ProduceItem(this, item);
		if (produced_item !is null)
		{
			this.server_PutInInventory(produced_item);

			item.produced.push_back(produced_item.getNetworkID());
			
			const bool hit_maximum = new_produced_amount+1 >= item.maximum_produced;
			item.next_time_to_produce = hit_maximum ? getGameTime() : getGameTime() + (item.seconds_to_produce*30) * production.modifier;
			
			CBitStream stream;
			stream.write_u8(index);
			stream.write_u32(item.next_time_to_produce);
			this.SendCommand(this.getCommandID("client_produce_item"), stream);
		}
	}
}

CBlob@ server_ProduceItem(CBlob@ this, ProductionItem@ item)
{
	Vec2f position = this.getPosition();
	position += this.exists("production offset") ? this.get_Vec2f("production offset") : Vec2f_zero;

	if (item.product_type == Product::crate)
	{
		CBlob@ blob = server_MakeCrate(item.blob_name, item.name, item.crate_frame_index, this.getTeamNum(), position);
		blob.set_u16("factory netid", this.getNetworkID()); //used to track the blob that comes out of the crate
		return blob;
	}
	else if (item.product_type == Product::seed)
	{
		CBlob@ blob = server_MakeSeed(position, item.blob_name);
		return blob;
	}
	else if (item.product_type == Product::scroll)
	{
		CBlob@ blob = server_MakePredefinedScroll(position, item.blob_name);
		return blob;
	}

	CBlob@ blob = server_CreateBlobNoInit(item.blob_name);
	if (blob !is null)
	{
		blob.server_setTeamNum(this.getTeamNum());
		blob.setPosition(position);
		blob.Init();
	}

	return blob;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	Production@ production;
	if (!this.get("production", @production)) return;

	if (cmd == this.getCommandID("client_produce_item") && isClient())
	{
		u8 index;
		if (!params.saferead_u8(index)) { error("Failed to produce item [0] : "+this.getNetworkID()); return; }

		if (index >= production.production_items.length)
		{
			error("Production items length does not match index! :: FactoryProduction.as, client_produce_item");
			return;
		}
		ProductionItem@ item = production.production_items[index];
		if (!params.saferead_u32(item.next_time_to_produce)) { error("Failed to produce item [1] : "+this.getNetworkID()); return; }

		const string sound = this.exists("produce sound") ? this.get_string("produce sound") : "BombMake.ogg";
		this.getSprite().PlaySound(sound);
	}
	else if (cmd == this.getCommandID("client_set_produce_time") && isClient())
	{
		u8 index;
		if (!params.saferead_u8(index)) { error("Failed to set produce time [0] : "+this.getNetworkID()); return; }

		if (index >= production.production_items.length)
		{
			error("Production items length does not match index! :: FactoryProduction.as, client_set_produce_time");
			return;
		}
		ProductionItem@ item = production.production_items[index];
		if (!params.saferead_u32(item.next_time_to_produce)) { error("Failed to set produce time [1] : "+this.getNetworkID()); return; }
	}
}

/// SPRITE

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;
	
	if (!localBlob.isKeyPressed(key_use) || getHUD().hasMenus()) return;

	CBlob@ blob = this.getBlob();
	if (!blob.get_bool("can produce")) return;

	Vec2f pos = blob.getPosition();
	Vec2f pos2d = blob.getScreenPos();
	Vec2f mouseworld = getControls().getMouseWorldPos();
	const bool mouseOnBlob = (mouseworld - pos).getLength() < blob.getRadius();
	if (mouseOnBlob || (localBlob.getPosition() - pos).getLength() < blob.getRadius())
	{
		CCamera@ camera = getCamera();
		const f32 zoom = camera.targetDistance;
		const int top = pos2d.y - zoom * blob.getHeight() + 22.0f;
		const u8 margin = 7;
		Vec2f dim;
		string label = "Level 10000";
		GUI::GetTextDimensions(label, dim);
		dim.x += 2.0f * margin;
		dim.y += 2.0f * margin;
		dim.x *= 0.8f;
		dim.y *= 0.9f;

		//if (mouseOnBlob) blob.RenderForHUD(RenderStyle::light);

		Production@ production;
		if (!blob.get("production", @production)) return;

		f32 initX = pos2d.x - production.production_items.length * dim.x / 4.0f - 12.0f;
		for (u8 i = 0 ; i < production.production_items.length; i++)
		{
			ProductionItem@ item = production.production_items[i];
			if (item is null) continue;

			const u32 time = getGameTime() - (item.next_time_to_produce - item.seconds_to_produce * 30);
			const f32 progress = f32(time) / f32(item.seconds_to_produce * 30);

			Vec2f iconDim;
			GUI::GetIconDimensions(item.icon_name, iconDim);

			Vec2f upperleft(initX, top);
			const f32 width = 32.0f + iconDim.x;
			Vec2f lowerright(upperleft.x + width, top + dim.y);
			initX += width + 1.0f;

			Vec2f mouse = getControls().getMouseScreenPos();
			const bool mouseHover = (mouse.x > upperleft.x && mouse.x < lowerright.x && mouse.y > upperleft.y && mouse.y < lowerright.y);
			const bool available = item.next_time_to_produce + TICK_FREQUENCY <= getGameTime();

			if (available)
			{
				GUI::DrawPane(upperleft, lowerright, SColor(255, 60, 255, 30));
			}
			else
			{
				GUI::DrawProgressBar(upperleft, lowerright, progress);
			}

			if (mouseHover)
			{
				string reqsText;

				if (!available)
					reqsText += getTranslatedString("Producing {ITEM}...").replace("{ITEM}", item.name);
				else
					reqsText += getTranslatedString("{ITEM} limit reached.").replace("{ITEM}", item.name);

				GUI::SetFont("menu");
				GUI::DrawText(reqsText, Vec2f(upperleft.x - 25.0f, lowerright.y + 20.0f), Vec2f(lowerright.x + 25.0f, lowerright.y + 100.0f), color_black, false, false, true);
			}

			GUI::DrawIconByName(item.icon_name, Vec2f(upperleft.x + 20.0f - iconDim.x, upperleft.y + (iconDim.y - dim.y) / 2 - 2));
		}
	}
}

/// NETWORKING

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	Production@ production;
	if (!this.get("production", @production))
	{
		stream.write_bool(false);
		return;
	}
	stream.write_bool(true);
	
	stream.write_string(production.name);
	stream.write_u8(production.frame);
	stream.write_CBitStream(production.reqs);
	
	stream.write_u8(production.production_items.length);
	for (u8 i = 0; i < production.production_items.length; i++)
	{
		ProductionItem@ item = production.production_items[i];
		stream.write_string(item.blob_name);
		stream.write_string(item.name);
		stream.write_string(item.icon_name);
		stream.write_u8(item.maximum_produced);
		stream.write_u32(item.seconds_to_produce);
		stream.write_u8(item.product_type);
		stream.write_u8(item.crate_frame_index);
		stream.write_u32(item.next_time_to_produce);
		
		/*stream.write_u8(item.produced.length);
		for (u8 i = 0; i < item.produced.length; i++)
		{
			stream.write_netid(item.produced[i]);
		}*/
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	if (!UnserializeProduction(this, stream))
	{
		error("Failed to access production! : "+this.getName()+" : "+this.getNetworkID());
		return false;
	}
	return true;
}

bool UnserializeProduction(CBlob@ this, CBitStream@ stream)
{
	bool sendData = false;
	if (!stream.saferead_bool(sendData)) return false;
	if (!sendData) return true;
	
	Production production;
	if (!stream.saferead_string(production.name))     return false;
	if (!stream.saferead_u8(production.frame))        return false;
	if (!stream.saferead_CBitStream(production.reqs)) return false;
	
	u8 production_items_length;
	if (!stream.saferead_u8(production_items_length)) return false;
	
	for (u8 i = 0; i < production_items_length; i++)
	{
		ProductionItem item;
		if (!stream.saferead_string(item.blob_name))         return false;
		if (!stream.saferead_string(item.name))              return false;
		if (!stream.saferead_string(item.icon_name))         return false;
		if (!stream.saferead_u8(item.maximum_produced))      return false;
		if (!stream.saferead_u32(item.seconds_to_produce))   return false;
		if (!stream.saferead_u8(item.product_type))          return false;
		if (!stream.saferead_u8(item.crate_frame_index))     return false;
		if (!stream.saferead_u32(item.next_time_to_produce)) return false;
		
		/*u8 produced_items_length;
		if (!stream.saferead_u8(produced_items_length)) return false;

		for (u8 i = 0; i < produced_items_length; i++)
		{
			u16 produced_id;
			if (!stream.saferead_netid(produced_id)) return false;
			item.produced.push_back(produced_id);
		}*/
		production.production_items.push_back(item);
	}
	
	this.set("production", @production);
	
	return true;
}
