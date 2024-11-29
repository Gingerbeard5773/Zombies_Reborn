// SonantDread & Gingerbeard @ November 14th 2024

#include "MakeScroll.as";
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "FactoryProductionCommon.as";

/*
 HOW TO SAVE CUSTOM BLOB DATA FOR YOUR MOD
 1) Create a blob handler class for your blob, with the applicable functions.
 2) Then set the class with the associated blob name into InitializeBlobHandlers().
 3) Delete the save file every time you modify blob handlers- doing this will avoid crashes caused by faulty data reading
*/

const string SaveFile = "Zombie_Save";

dictionary blobHandlers;
void InitializeBlobHandlers()
{
	if (blobHandlers.getSize() != 0) return;

	blobHandlers.set("default",    BlobDataHandler());
	blobHandlers.set("seed",       SeedBlobHandler());
	blobHandlers.set("crate",      CrateBlobHandler());
	blobHandlers.set("scroll",     ScrollBlobHandler());
	blobHandlers.set("lever",      LeverBlobHandler());
	blobHandlers.set("library",    LibraryBlobHandler());
	blobHandlers.set("factory",    FactoryBlobHandler());

	blobHandlers.set("tree_bushy", TreeBlobHandler());
	blobHandlers.set("tree_pine",  TreeBlobHandler());

	blobHandlers.set("forge",      ForgeBlobHandler());
	blobHandlers.set("quarry",     ForgeBlobHandler());

	blobHandlers.set("builder",    PlayerBlobHandler());
	blobHandlers.set("knight",     PlayerBlobHandler());
	blobHandlers.set("archer",     PlayerBlobHandler());
}

bool canSaveBlob(CBlob@ blob)
{
	const string name = blob.getName();
	if (name == "skelepedebody") return false;

	if (blob.hasTag("temp blob") || blob.hasTag("projectile")) return false;

	if (!blob.hasTag("undead") && blob.hasTag("dead")) return false;

	//if (blob.getPlayer() !is null) return false;

	return true;
}

BlobDataHandler@ basicHandler = BlobDataHandler();
class BlobDataHandler
{
	// Write our blob's information into the config
	// Each piece of data must be divided by the token ';'
	string Serialize(CBlob@ blob)
	{
		string data = blob.getName() + ";";
		Vec2f pos = blob.getPosition();
		data += pos.x + ";" + pos.y + ";";
		data += blob.getHealth() + ";";
		data += blob.getTeamNum() + ";";
		data += blob.getShape().isStatic() ? "1;" : "0;";
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

	// Load in any special properties/states for the particular blob
	// Note; all other classes will need updated if you change the amount of data that is processed in this base class
	void LoadBlobData(CBlob@ blob, const string[]@ data)
	{
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
		string data = basicHandler.Serialize(blob);
		data += blob.get_string("seed_grow_blobname") + ";";
		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		const string seedName = data[9];
		return server_MakeSeed(pos, seedName);
	}
}

class CrateBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);
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
		string data = basicHandler.Serialize(blob);
		data += blob.get_string("scroll defname0") + ";";
		return data;
	}

	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		const string scroll_name = data[9];
		return server_MakePredefinedScroll(pos, scroll_name);
	}
}

class LeverBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);
		data += (blob.get_bool("activated") ? "1;" : "0;");
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		basicHandler.LoadBlobData(blob, data);
		const bool activated = parseBool(data[9]);
		blob.set_bool("activated", activated);
	}
}

class LibraryBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);
		data += blob.get_s32("researching") + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		basicHandler.LoadBlobData(blob, data);
		const int researching = parseInt(data[9]);
		blob.set_s32("researching", researching);
	}
}

class FactoryBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);

		Production@ production;
		if (blob.get("production", @production))
		{
			data += production.name + ";";
		}

		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		basicHandler.LoadBlobData(blob, data);

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
	CBlob@ CreateBlob(const string&in name, const Vec2f&in pos, const string[]@ data) override
	{
		CBlob@ blob = server_CreateBlobNoInit(name);
		blob.setPosition(pos);
		blob.Tag("startbig");
		blob.Init();
		return blob;
	}
}

class ForgeBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);
		data += blob.get_s16("fuel_level") + ";";
		return data;
	}

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		basicHandler.LoadBlobData(blob, data);
		const s16 fuel_level = parseInt(data[9]);
		blob.set_s16("fuel_level", fuel_level);
	}
}

class PlayerBlobHandler : BlobDataHandler
{
	string Serialize(CBlob@ blob) override
	{
		string data = basicHandler.Serialize(blob);

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

	void LoadBlobData(CBlob@ blob, const string[]@ data) override
	{
		basicHandler.LoadBlobData(blob, data);
		const string username = data.length > 9 ? data[9] : "";
		const u16 coins = data.length > 10 ? parseInt(data[10]) : 0;
		if (!username.isEmpty())
		{
			blob.set_string("sleeper_name", username);
			blob.set_u16("sleeper_coins", coins);
			blob.Tag("sleeper");
		}
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
