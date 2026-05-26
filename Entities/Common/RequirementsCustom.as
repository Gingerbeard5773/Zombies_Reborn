// Custom Requirements
// Gingerbeard @ March 2nd, 2026

// This rewrite allows for far more flexibility.
// Instead of only checking requirements for two inventories, this system allows for an infinite amount.
// So for example, this rewrite could be used to make the remote storage system from TC if wanted.
// This system also is decoupled from inventories entirely, so if you dont even want to check from inventories you can do that.

void AddRequirement(CBitStream@ bs, const string &in req, const string &in blobName, const string &in friendlyName, const u16 &in quantity = 1)
{
	bs.write_string(req);
	bs.write_string(blobName);
	bs.write_string(friendlyName);
	bs.write_u16(quantity);
}

bool ReadRequirement(CBitStream@ bs, string &out req, string &out blobName, string &out friendlyName, u16 &out quantity)
{
	if (!bs.saferead_string(req))          return false;
	if (!bs.saferead_string(blobName))     return false;
	if (!bs.saferead_string(friendlyName)) return false;
	if (!bs.saferead_u16(quantity))        return false;
	return true;
}

bool hasRequirements(CBlob@[]@ blobs, CBitStream@ bs)
{
	string req, blobName, friendlyName;
	u16 quantity = 0;
	bs.ResetBitIndex();
	bool has = true;

	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, req, blobName, friendlyName, quantity);

		if (!hasRequirement(blobs, req, blobName, quantity))
		{
			has = false;
		}
	}

	bs.ResetBitIndex();
	return has;
}

bool hasRequirement(CBlob@[]@ blobs, string req, string blobName, const u16 quantity)
{
	int taken = 0;
	if (req == "blob")
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob.getName() != blobName) continue;

			taken += blob.getQuantity();

			if (taken >= quantity) return true;
		}
	}
	else if (req == "coin")
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CPlayer@ player = blobs[i].getPlayer();
			if (player is null) continue;

			taken += player.getCoins();

			if (taken >= quantity) return true;
		}
	}

	return false;
}

void server_TakeRequirements(CBlob@[]@ blobs, CBitStream@ bs)
{
	CBlob@[] used;
	server_TakeRequirements(blobs, bs);
}

void server_TakeRequirements(CBlob@[]@ blobs, CBitStream@ bs, CBlob@[]@ used)
{
	if (!isServer()) return;

	string req, blobName, friendlyName;
	u16 quantity;
	bs.ResetBitIndex();
	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, req, blobName, friendlyName, quantity);

		int taken = 0;
		if (req == "blob")
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() != blobName) continue;

				const u16 take = Maths::Min(blob.getQuantity(), quantity - taken);
				blob.server_SetQuantity(blob.getQuantity() - take);

				if (blob.getQuantity() <= 0)
				{
					used.push_back(blob);
					blob.server_Die();
				}

				taken += take;
			}
		}
		else if (req == "coin")
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CPlayer@ player = blobs[i].getPlayer();
				if (player is null) continue;

				const u16 take = Maths::Min(player.getCoins(), quantity - taken);
				player.server_setCoins(player.getCoins() - take);

				taken += take;
			}
		}
	}

	bs.ResetBitIndex();
}

string getRequirementText(CBlob@[]@ blobs, CBitStream@ bs)
{
	string text, req, blobName, friendlyName;
	u16 quantity = 0;
	bs.ResetBitIndex();

	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, req, blobName, friendlyName, quantity);

		const bool hasReq = hasRequirement(blobs, req, blobName, quantity);

		const string col = hasReq ? "$GREEN$" : "$RED$";

		if (req == "blob")
		{
			if (quantity > 0)
			{
				text += col;
				text += quantity;
				text += col;
				text += " ";
			}
			text += "$"; text += blobName; text += "$";
			text += " ";
			text += col;
			text += getTranslatedString(friendlyName);
			text += col;
			// text += " required.";
			text += "\n";
		}
		else if (req == "coin")
		{
			text += getTranslatedString("{COINS_QUANTITY} $COIN$ required\n").replace("{COINS_QUANTITY}", "" + quantity);
		}
	}

	bs.ResetBitIndex();
	return text;
}

bool getBlobsInInventory(CBlob@ blob, CBlob@[]@ items)
{
	CInventory@ inventory = blob.getInventory();
	if (inventory is null) return false;

	int items_count = inventory.getItemsCount();
	for (int i = 0; i < items_count; i++)
	{
		items.push_back(inventory.getItem(i));
	}

	CBlob@ carried = blob.getCarriedBlob();
	if (carried !is null)
	{
		items.push_back(carried);
		items_count++;
	}

	return items_count > 0;
}

CBlob@[]@ getRequirementBlobs(CBlob@ blob)
{
	// Use blobs in our inventory as well as blobs around us
	CBlob@[] blobs;
	getBlobsInInventory(blob, @blobs);
	getMap().getBlobsInRadius(blob.getPosition(), 64.0f, @blobs);

	return blobs;
}
