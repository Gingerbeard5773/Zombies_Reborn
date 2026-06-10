// SonantDread & Gingerbeard @ November 14th 2024

#include "MakeScroll.as"
#include "MakeSeed.as"
#include "MakeCrate.as"
#include "FactoryProductionCommon.as"

/*
 HOW TO SAVE CUSTOM BLOB DATA FOR YOUR MOD
 1) Create a blob handler class for your blob, with the applicable functions.
 2) Then set the class with the associated blob name into InitializeBlobHandlers().
*/

dictionary blobHandlers;
void InitializeBlobHandlers()
{
	if (blobHandlers.getSize() != 0) return;

	blobHandlers.set("default",        BlobDataHandler());
	blobHandlers.set("seed",           SeedBlobHandler());
	blobHandlers.set("crate",          CrateBlobHandler());
	blobHandlers.set("scroll",         ScrollBlobHandler());
	blobHandlers.set("lever",          LeverBlobHandler());
	blobHandlers.set("clock",          ClockBlobHandler());
	blobHandlers.set("library",        LibraryBlobHandler());
	blobHandlers.set("factory",        FactoryBlobHandler());

	blobHandlers.set("tree_bushy",     TreeBlobHandler());
	blobHandlers.set("tree_pine",      TreeBlobHandler());

	blobHandlers.set("forge",          ForgeBlobHandler());
	blobHandlers.set("quarry",         ForgeBlobHandler());

	blobHandlers.set("builder",        PlayerBlobHandler());
	blobHandlers.set("knight",         PlayerBlobHandler());
	blobHandlers.set("archer",         PlayerBlobHandler());
	blobHandlers.set("wizard",         PlayerBlobHandler());

	blobHandlers.set("migrant",        MigrantBlobHandler()); // LEGACY MAPS SUPPORT

	blobHandlers.set("bobert",         TraderBlobHandler());
	blobHandlers.set("traderbomber",   TraderBlobHandler());

	blobHandlers.set("bomber",         BomberBlobHandler());
	blobHandlers.set("armoredbomber",  BomberBlobHandler());

	blobHandlers.set("enchanter",      EnchanterBlobHandler());
	
	blobHandlers.set("pyromancer",     PyromancerBlobHandler());

	blobHandlers.set("sign",           SignBlobHandler());
}

bool canSaveBlob(CBlob@ blob)
{
	const string name = blob.getName();
	if (name == "skelepedebody" || name == "spike") return false;

	if (blob.hasTag("temp blob") || blob.hasTag("projectile")) return false;

	if (!blob.hasTag("undead") && blob.hasTag("dead")) return false;

	return true;
}

class BlobDataHandler
{
	// Write our blob's information into the config
	// Each piece of data must be divided by the token ';'
	// Important: Do not save non-existant info like empty strings!
	string Serialize(CBlob@ blob)
	{
		string data = blob.getName() + ";";
		CShape@ shape = blob.getShape();
		Vec2f pos = blob.getPosition();
		data += pos.x + ";" + pos.y + ";";
		data += blob.getHealth() + ";";
		data += blob.getTeamNum() + ";";
		data += shape !is null && shape.isStatic() ? "1;" : "0;";
		data += blob.getAngleDegrees() + ";";
		data += blob.getQuantity() + ";";
		data += blob.isFacingLeft() ? "1;" : "0;";
		return data;
	}

	// Creation protocols for the particular blob
	// Necessary because some blobs must have data set to the blob *before* the blob is initialized. 
	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data)
	{
		return server_CreateBlob(name, 0, pos);
	}

	// Load in any special properties/states for the particular blob *after* it is initialized.
	// Note; all other classes will need updated if you change the amount of data that is processed in this base class
	void LoadBlobData(CBlob@ blob, const string[]@ data)
	{
		if (data.length < 9) { error("MapSaver: Failed to load basic blob data ["+blob.getName()+"]"); return; }

		const f32 health = parseFloat(data[3]);
		const int team = parseInt(data[4]);
		const bool isStatic = parseBool(data[5]);
		const f32 angle = parseFloat(data[6]);
		const u16 quantity = parseInt(data[7]);
		const bool facingLeft = parseBool(data[8]);

		blob.server_SetHealth(health <= 0.0f ? blob.getInitialHealth() : health);
		blob.server_setTeamNum(team);
		blob.setAngleDegrees(angle);
		blob.getShape().SetStatic(isStatic);
		blob.server_SetQuantity(quantity);
		blob.SetFacingLeft(facingLeft);
	}
}

class SeedBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		const string seed_name = blob.exists("seed_grow_blobname") ? blob.get_string("seed_grow_blobname") : "";
		if (!seed_name.isEmpty())
		{
			data += seed_name + ";";
		}
		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		const string seed_name = data.length > 9 ? data[9] : "";
		if (!seed_name.isEmpty())
		{
			return server_MakeSeed(pos, seed_name);
		}
		return BlobDataHandler::CreateBlob(name, pos, data);
	}
}

class CrateBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		const string packed = blob.exists("packed") ? blob.get_string("packed") : "";
		if (!packed.isEmpty())
		{
			data += packed + ";";
		}
		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		CBlob@ crate = server_CreateBlobNoInit("crate");
		crate.setPosition(pos);
		const string packed = data.length > 9 ? data[9] : "";
		if (!packed.isEmpty())
		{
			crate.set_string("packed", packed);
		}
		crate.Init();
		return crate;
	}
}

class ScrollBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		const string scroll_name = blob.exists("scroll defname0") ? blob.get_string("scroll defname0") : "";
		if (!scroll_name.isEmpty())
		{
			data += scroll_name + ";";
			if (isSpecialScroll(scroll_name))
			{
				data += blob.get_bool("used") ? "1;" : "0;";
				data += blob.get_u32("current_increment") + ";";
			}

			if (scroll_name == "rewind")
			{
				data += blob.getNetworkID() + ";";
			}
		}

		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		const string scroll_name = data.length > 9 ? data[9] : "";

		if (scroll_name == "rewind" && getRules().exists("time_travel_netid"))
		{
			const u16 netid = data.length > 10 ? parseInt(data[10]) : 0;
			if (netid == getRules().get_netid("time_travel_netid"))
			{
				return null;
			}
		}

		if (!scroll_name.isEmpty())
		{
			return server_MakePredefinedScroll(pos, scroll_name);
		}
		return BlobDataHandler::CreateBlob(name, pos, data);
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const string scroll_name = data.length > 9 ? data[9] : "";
		if (isSpecialScroll(scroll_name))
		{
			const bool used = data.length > 10 ? parseBool(data[10]) : false;
			const u32 current_increment = data.length > 11 ? parseInt(data[11]) : 0;
			blob.set_bool("used", used);
			blob.set_u32("current_increment", current_increment);
		}
	}

	bool isSpecialScroll(const string&in scroll_name)
	{
		return scroll_name == "time" || scroll_name == "desiccation";
	}
}

class LeverBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_bool("activated") ? "1;" : "0;";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const bool activated = data.length > 9 ? parseBool(data[9]) : false;
		blob.set_bool("activated", activated);
	}
}

class ClockBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);

		bool[]@ hours_activated;
		if (blob.get("hours_activated", @hours_activated))
		{
			string bool_line;
			for (u8 i = 0; i < hours_activated.length; i++)
			{
				bool_line += (hours_activated[i] ? "1" : "0");
			}
			data += bool_line + ";";
		}

		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const string bool_line = data.length > 9 ? data[9] : "";

		bool[] hours_activated(bool_line.length);
		for (u8 i = 0; i < bool_line.length; i++)
		{
			hours_activated[i] = bool_line[i] == 49; //1 in ascii
		}
		blob.set("hours_activated", hours_activated);
	}
}

class LibraryBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_s32("researching") + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const int researching = data.length > 9 ? parseInt(data[9]) : 0;
		blob.set_s32("researching", researching);
	}
}

class FactoryBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);

		Production@ production;
		if (blob.get("production", @production))
		{
			data += production.name + ";";
		}

		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);

		if (data.length <= 9) return;

		Production@[]@ production_set;
		if (!getRules().get("factory_production_set", @production_set)) return;

		const string factory_name = data[9];
		for (u8 i = 0; i < production_set.length; i++)
		{
			Production@ production = production_set[i];
			if (production.name != factory_name) continue;

			SetFactoryDataHandle@ SetFactoryData;
			if (blob.get("SetFactoryData handle", @SetFactoryData))
			{
				SetFactoryData(blob, production);
			}
			break;
		}
	}
}

class TreeBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_u8("grown_times") + ";";
		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		CBlob@ blob = server_CreateBlobNoInit(name);
		if (blob !is null)
		{
			const u8 grown_times = data.length > 9 ? parseInt(data[9]) : 15;
			blob.set_u8("grown_times", grown_times);
			blob.setPosition(pos);
			blob.Init();
		}
		return blob;
	}
}

class ForgeBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_s16("fuel_level") + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const s16 fuel_level = data.length > 9 ? parseInt(data[9]) : 0;
		blob.set_s16("fuel_level", fuel_level);
	}
}

class PlayerBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);

		string username = "";
		u16 coins = 0;
		CPlayer@ player = blob.getPlayer();
		if (player !is null)
		{
			username = player.getUsername();
			coins = player.getCoins();
		}
		else if (blob.exists("sleeper_name"))
			username = blob.get_string("sleeper_name");

		if (!username.isEmpty())
		{
			data += username + ";";
			data += coins + ";";
		}

		return data;
	}
	
	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		CBlob@ blob = server_CreateBlobNoInit(name);
		if (blob !is null)
		{
			const int team = parseInt(data[4]);
			const string username = data.length > 9 ? data[9] : "";
			const u16 coins = data.length > 10 ? parseInt(data[10]) : 0;
			if (!username.isEmpty())
			{
				blob.set_string("sleeper_name", username);
				blob.set_u16("sleeper_coins", coins);
				blob.Tag("sleeper");
			}
			blob.setPosition(pos);
			blob.server_setTeamNum(team);
			blob.Init();
		}
		return blob;
	}
}

class MigrantBlobHandler : BlobDataHandler
{
	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		return BlobDataHandler::CreateBlob("builder", pos, data);
	}
}

class TraderBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += (blob.get_u32("time till departure") - getGameTime()) + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const u32 time_left = data.length > 9 ? parseInt(data[9]) : 0;
		blob.set_u32("time till departure", time_left);
	}
}

class BomberBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_f32("fly_amount") + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const f32 fly_amount = data.length > 9 ? parseFloat(data[9]) : 0.0f;
		blob.set_f32("fly_amount", fly_amount);
	}
}

class EnchanterBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_bool("enchanter_paid") ? "1;" : "0;";
		data += blob.get_u8("enchants_count") + ";";
		data += (blob.get_u32("time till departure") - getGameTime()) + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const bool enchanter_paid = data.length > 9 ? parseBool(data[9]) : false;
		const u8 enchants_count = data.length > 10 ? parseInt(data[10]) : 0;
		const u32 time_left = data.length > 11 ? parseInt(data[11]) : 0;
		blob.set_bool("enchanter_paid", enchanter_paid);
		blob.set_u8("enchants_count", enchants_count);
		blob.set_u32("time till departure", time_left);
	}
}

class PyromancerBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		data += blob.get_u8("introduction_time") + ";";
		data += blob.get_u16("brain_movement_delay") + ";";
		
		Vec2f destination = blob.get_Vec2f("brain_destination");
		data += destination.x + ";" + destination.y + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		if (data.length < 13) return;

		const u8 intro_time = parseInt(data[9]);
		const u16 movement_delay = parseInt(data[10]);
		const f32 destination_x = parseFloat(data[11]);
		const f32 destination_y = parseFloat(data[12]);
		blob.set_u8("introduction_time", intro_time);
		blob.set_u16("brain_movement_delay", movement_delay);
		blob.set_Vec2f("brain_destination", Vec2f(destination_x, destination_y));
	}
}

class SignBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = BlobDataHandler::Serialize(blob);
		const string text = blob.exists("text") ? blob.get_string("text") : "";
		if (!text.isEmpty())
		{
			data += blob.get_string("text") + ";";
		}
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		BlobDataHandler::LoadBlobData(blob, data);
		const string text = data.length > 9 ? data[9] : "";
		blob.set_string("text", text);
	}
}

BlobDataHandler@ getBlobHandler(const string&in name)
{
	BlobDataHandler@ handler;
	if (!blobHandlers.get(name, @handler))
	{
		blobHandlers.get("default", @handler);
	}

	return handler;
}

bool parseBool(const string&in data)
{
	return data == "1";
}
