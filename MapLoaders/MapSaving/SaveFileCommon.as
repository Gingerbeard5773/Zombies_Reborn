// Savefile Common

namespace Save
{
	const string SaveFileName = "Zombie_Save_";
	const string AllSavesFileName = "Zombie_Saves";
}

shared class SaveFile
{
	string map_dimensions;
	string map_data;
	string dirt_data;
	string water_data;
	string blob_data;
	string inventory_data;
	string attachment_data;
	string owner_data;
	string equipment_data;
	string task_data;
	u16 day_number;
	f32 day_time;
	u16 bobert_day;
	string tech_data;
	s32 map_seed;

	SaveFile() {}

	SaveFile(ConfigFile@ config)
	{
		map_dimensions = config.read_string("map_dimensions", "");
		map_data = config.read_string("map_data", "");
		dirt_data = config.read_string("dirt_data", "");
		water_data = config.read_string("water_data", "");
		blob_data = config.read_string("blob_data", "");
		inventory_data = config.read_string("inventory_data", "");
		attachment_data = config.read_string("attachment_data", "");
		owner_data = config.read_string("owner_data", "");
		equipment_data = config.read_string("equipment_data", "");
		task_data = config.read_string("task_data", "");
		day_number = config.read_u16("day_number", 1);
		day_time = config.read_f32("day_time", 0.2f);
		bobert_day = config.read_u16("bobert_day", 0);
		tech_data = config.read_string("tech_data", "");
		map_seed = config.read_s32("map_seed", 0);
	}

	void Write(ConfigFile@ config)
	{
		config.add_string("map_dimensions", map_dimensions);
		config.add_string("map_data", map_data);
		config.add_string("dirt_data", dirt_data);
		config.add_string("water_data", water_data);
		config.add_string("blob_data", blob_data);
		config.add_string("inventory_data", inventory_data);
		config.add_string("attachment_data", attachment_data);
		config.add_string("owner_data", owner_data);
		config.add_string("equipment_data", equipment_data);
		config.add_string("task_data", task_data);
		config.add_u16("day_number", day_number);
		config.add_f32("day_time", day_time);
		config.add_u16("bobert_day", bobert_day);
		config.add_string("tech_data", tech_data);
		config.add_s32("map_seed", map_seed);
	}

	void Serialize(CBitStream@ stream)
	{
		stream.write_string(map_dimensions);
		WriteDivided(map_data, stream);
		WriteDivided(dirt_data, stream);
		WriteDivided(water_data, stream);
		WriteDivided(blob_data, stream);
		WriteDivided(inventory_data, stream);
		WriteDivided(attachment_data, stream);
		WriteDivided(owner_data, stream);
		WriteDivided(task_data, stream);
		stream.write_u16(day_number);
		stream.write_f32(day_time);
		stream.write_u16(bobert_day);
		stream.write_string(tech_data);
		stream.write_s32(map_seed);
	}

	bool Unserialize(CBitStream@ stream)
	{
		if (!stream.saferead_string(map_dimensions))  { error("Failed to read map_dimensions [SaveFileCommon]");  return false; }
		if (!ReadDivided(map_data, stream))           { error("Failed to read map_data [SaveFileCommon]");        return false; }
		if (!ReadDivided(dirt_data, stream))          { error("Failed to read dirt_data [SaveFileCommon]");       return false; }
		if (!ReadDivided(water_data, stream))         { error("Failed to read water_data [SaveFileCommon]");      return false; }
		if (!ReadDivided(blob_data, stream))          { error("Failed to read blob_data [SaveFileCommon]");       return false; }
		if (!ReadDivided(inventory_data, stream))     { error("Failed to read inventory_data [SaveFileCommon]");  return false; }
		if (!ReadDivided(attachment_data, stream))    { error("Failed to read attachment_data [SaveFileCommon]"); return false; }
		if (!ReadDivided(owner_data, stream))         { error("Failed to read owner_data [SaveFileCommon]");      return false; }
		if (!ReadDivided(task_data, stream))          { error("Failed to read task_data [SaveFileCommon]");       return false; }
		if (!stream.saferead_u16(day_number))         { error("Failed to read day_number [SaveFileCommon]");      return false; }
		if (!stream.saferead_f32(day_time))           { error("Failed to read day_time [SaveFileCommon]");        return false; }
		if (!stream.saferead_u16(bobert_day))         { error("Failed to read bobert_day [SaveFileCommon]");      return false; }
		if (!stream.saferead_string(tech_data))       { error("Failed to read tech_data [SaveFileCommon]");       return false; }
		if (!stream.saferead_s32(map_seed))           { error("Failed to read map_seed [SaveFileCommon]");        return false; }

		return true;
	}

	/// CBitstream has limits that we have to bypass when dealing with these massive strings

	void WriteDivided(const string&in data, CBitStream@ stream)
	{
		const u32 chunk_size = 500;
		const u32 data_length = data.size();
		const u16 chunks_count = (data_length + chunk_size - 1) / chunk_size;
		stream.write_u16(chunks_count);

		for (u16 i = 0; i < chunks_count; i++)
		{
			const u32 start = i * chunk_size;
			const int count = Maths::Min(chunk_size, data_length - start);

			stream.write_string(data.substr(start, count));
		}
	}

	bool ReadDivided(string&out data, CBitStream@ stream)
	{
		u16 chunks_count;
		if (!stream.saferead_u16(chunks_count)) return false;

		data = "";

		for (u16 i = 0; i < chunks_count; i++)
		{
			string part;
			if (!stream.saferead_string(part)) return false;

			data += part;
		}

		return true;
	}
}
