// CBitStream Divider
// Gingerbeard @ May 8th, 2026

/*
 CBitstream has a limit to the size of each write. This causes failures when writing massive strings.
 The solution is simple- just divide up the strings into several writes.
*/

// Works functionally the same as [ void write_string(string str) ]
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

// Works functionally the same as [ bool saferead_string(string&out) ]
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
