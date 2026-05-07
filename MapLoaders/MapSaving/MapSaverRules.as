// Gingerbeard @ November 23, 2024

//this script MUST be the last script to be called in gamemode.cfg

#include "MapSaver.as"
#include "Zombie_DaysCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "PlayerPermissions.as"

const u8 TIME_TRAVEL_DAYS = 2; // also edit ScrollRewind.as to fully change this

void onInit(CRules@ this)
{
	this.addCommandID("server_load_save");
	this.addCommandID("client_load_dirt");
	this.addCommandID("client_load_damage_owners");

	if (isServer())
	{
		addOnNewDayHour(this, @onNewDayHour);

		LoadSavedRules(this, getMap());
	}
}

void onRestart(CRules@ this)
{
	if (isServer())
	{
		CMap@ map = getMap();

		LoadSavedRules(this, map);

		onTimeTravelComplete(this, map);

		if (!isClient())
		{
			CBitStream stream;
			stream.write_string(SerializeDirtData(map));
			this.SendCommand(this.getCommandID("client_load_dirt"), stream);
		}
	}
}

void onTimeTravelComplete(CRules@ this, CMap@ map)
{
	if (this.exists("time_travel_netid") && this.get_netid("time_travel_netid") > 0)
	{
		server_SendGlobalSound(this, "Revive.ogg");
		server_SendGlobalMessage(this, "ScrollRewindFinish", 8, ConsoleColour::CRAZY.color);

		const string[] inputs = {this.get_u16("day_number")+""};
		server_SendGlobalMessage(this, "Day", 8, inputs);

		this.set_netid("time_travel_netid", 0);

		// overwrite the save so our time travel scroll can't ever reappear 
		SaveMap(this, map, this.get_string("mapsaver_save_slot"));
	}
}

void onNewDayHour(CRules@ this, u16 day_hour)
{
	const u16 day_number = this.get_u16("day_number");

	// standard auto-save
	if (day_hour == 4)
	{
		print("AUTOSAVING MAP: AutoSave [DAY " + day_number + "]", 0xff66C6FF);
		SaveMap(this, getMap());
	}

	// time travel auto-saves
	if (day_hour == 3)
	{
		const u16 num = day_number % (TIME_TRAVEL_DAYS + 1);
		print("AUTOSAVING MAP: TimeSave" + num + " [DAY " + day_number + "]", 0xff66C6FF);
		SaveMap(this, getMap(), "TimeSave"+num);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	onDamageOwnerLeave(this, player);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	onDamageOwnerRejoin(this, player);
	
	if (!isClient())
	{
		CBitStream stream;
		stream.write_string(SerializeDirtData(getMap()));
		this.SendCommand(this.getCommandID("client_load_dirt"), stream, player);
	}
}

void onDamageOwnerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@[] blobs;
	getBlobs(@blobs);

	// cache our leaving player's owned blobs
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];

		CPlayer@ owner_player = blob.getDamageOwnerPlayer();
		if (owner_player is null || owner_player !is player || owner_player.isBot()) continue;

		blob.set_string("damage_owner", player.getUsername());
	}
}

void onDamageOwnerRejoin(CRules@ this, CPlayer@ player)
{
	CBlob@[] blobs;
	getBlobs(@blobs);

	// set our damage owner blobs for our new player
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!blob.exists("damage_owner")) continue;

		if (blob.getDamageOwnerPlayer() !is null) continue;

		if (blob.get_string("damage_owner") != player.getUsername()) continue;

		blob.SetDamageOwnerPlayer(player);
	}

	if (!isClient())
	{
		CBitStream stream;
		SerializeDamageOwnerPlayers(blobs, stream);
		this.SendCommand(this.getCommandID("client_load_damage_owners"), stream, player);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_load_save") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		bool isAdmin, isSuperAdmin;
		getPermissions(player, isAdmin, isSuperAdmin);

		if (!isAdmin && !isSuperAdmin) return;

		SaveFile@ save = SaveFile();
		if (!save.Unserialize(params)) { error("Failed to read save file [LoadSavedRules]"); return; }

		print("LOADING SAVED MAP FROM CLIENT: "+player.getUsername(), 0xff66C6FF);

		ConfigFile@ config = ConfigFile();
		save.Write(config);
		config.saveFile(Save::SaveFileName + "ClientRequest");

		this.set_string("mapsaver_save_slot", "ClientRequest");
		this.set_bool("loaded_saved_map", false);
		LoadNextMap();
	}
	else if (cmd == this.getCommandID("client_load_dirt") && isClient())
	{
		// synchronizing dirt data manually may be unnecessary in a future KAG engine update
		string dirt_data;
		if (!params.saferead_string(dirt_data)) { error("Failed to read dirt_data [MapSaverRules]"); return; }

		LoadDirt(getMap(), dirt_data);
	}
	else if (cmd == this.getCommandID("client_load_damage_owners") && isClient())
	{
		UnserializeDamageOwnerPlayers(params);
	}
}


/// NETWORK

void SerializeDamageOwnerPlayers(CBlob@[]@ blobs, CBitStream@ stream)
{
	CBitStream data;
	u16 count = 0;

	for (u16 i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob is null) continue;

		CPlayer@ player = blob.getDamageOwnerPlayer();
		if (player is null) continue;

		data.write_netid(blob.getNetworkID());
		data.write_netid(player.getNetworkID());

		count++;
	}

	stream.write_u16(count);
	stream.write_CBitStream(data);
}

bool UnserializeDamageOwnerPlayers(CBitStream@ stream)
{
	u16 count;
	if (!stream.saferead_u16(count)) { error("Failed to read damage owner count [MapSaverRules]"); return false; }

	CBitStream data;
	if (!stream.saferead_CBitStream(data)) { error("Failed to read damage owner data [MapSaverRules]"); return false; }

	data.ResetBitIndex();

	for (u16 i = 0; i < count; i++)
	{
		u16 blob_netid, player_netid;
		if (!data.saferead_netid(blob_netid)) { error("Failed to read blob_netid [MapSaverRules]"); return false; }
		if (!data.saferead_netid(player_netid)) { error("Failed to read player_netid [MapSaverRules]"); return false; }

		CBlob@ blob = getBlobByNetworkID(blob_netid);
		CPlayer@ player = getPlayerByNetworkId(player_netid);
		if (blob is null || player is null) continue;

		blob.SetDamageOwnerPlayer(player);
	}

	return true;
}
