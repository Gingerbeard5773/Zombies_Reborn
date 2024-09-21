// Give spawn items to players

const string give_items_cmd = "give_spawn_mats";
const string timer_prop = "mats_time";

const u32 materials_wait = 20;

void onInit(CRules@ this)
{
	this.addCommandID(give_items_cmd);
}

void onRestart(CRules@ this)
{
	this.set_u32("builder" + timer_prop, 0);
	this.set_u32("archer" + timer_prop, 0);
}

//check if we can recieve mats from an applicable building
void onTick(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null || !player.isMyPlayer()) return;
	
	const u32 gameTime = getGameTime();
	if (gameTime % 15 != 5) return;
	
	CBlob@ blob = player.getBlob();
	if (blob is null) return;
	
	const string name = getRecieverName(blob);
	if (getMatsTime(this, name) > gameTime || !canReceiveMats(name)) return;

	CBlob@[] overlapping;
	if (blob.getOverlapping(@overlapping))
	{
		const u8 overlappingLength = overlapping.length;
		for (u8 i = 0; i < overlappingLength; ++i)
		{
			const string overlapped = overlapping[i].getName();
			if ((overlapped == "buildershop" && name == "builder") ||
				(overlapped == "archershop" && name == "archer") ||
				(overlapped == "barracks"))
			{
				client_GiveMats(this, player, blob);
			}
		}
	}
}

//when the player is set, give materials if possible
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer() && blob !is null)
	{
		const string name = getRecieverName(blob);
		if (getMatsTime(this, name) > getGameTime() || !canReceiveMats(name)) return;
		
		client_GiveMats(this, player, blob, true);
	}
}

const string getRecieverName(CBlob@ blob)
{
	const string name = blob.getName();
	
	if (name == "crossbowman") //use archer spawnmats for crossbow
		return "archer";
	
	return name;
}

const bool canReceiveMats(const string&in name)
{
	return name == "builder" || name == "archer";
}

const u32 getMatsTime(CRules@ this, const string&in name)
{
	return this.get_u32(name + timer_prop); 
}

void client_GiveMats(CRules@ this, CPlayer@ player, CBlob@ blob, const bool&in checkTimeAlive = false)
{
	this.set_u32(getRecieverName(blob) + timer_prop, getGameTime() + (materials_wait * getTicksASecond()));
	
	CBitStream params;
	params.write_u16(player.getNetworkID());
	params.write_netid(blob.getNetworkID());
	params.write_bool(checkTimeAlive);
	this.SendCommand(this.getCommandID(give_items_cmd), params);
}

void server_GiveMats(CRules@ this, CPlayer@ player, CBlob@ blob)
{
	const string name = getRecieverName(blob);
	if (name == "builder")
	{
		if (this.get_u16("day_number") < 2)
		{
			server_SpawnMats(blob, "mat_wood", 200);
			server_SpawnMats(blob, "mat_stone", 50);
		}
		else
		{
			server_SpawnMats(blob, "mat_wood", 100);
			server_SpawnMats(blob, "mat_stone", 30);
		}
	}
	else if (name == "archer")
	{
		server_SpawnMats(blob, "mat_arrows", 30);
	}
}

void server_SpawnMats(CBlob@ blob, const string&in name, const int&in quantity)
{
	//avoid over-stacking arrows
	if (name == "mat_arrows")
	{
		blob.getInventory().server_RemoveItems(name, quantity);
	}

	CBlob@ mat = server_CreateBlobNoInit(name);
	if (mat !is null)
	{
		mat.Tag("custom quantity");
		mat.Init();

		mat.server_SetQuantity(quantity);

		if (!blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(give_items_cmd) && isServer())
	{
		CPlayer@ player = getPlayerByNetworkId(params.read_u16());
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (player is null || blob is null) return;
		
		const bool checkTimeAlive = params.read_bool();
		if (checkTimeAlive && blob.getTickSinceCreated() > 10) return;
		
		server_GiveMats(this, player, blob);
	}
}

//render gui for the player
void onRender(CRules@ this)
{
	if (g_videorecording || this.isGameOver()) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null || !player.isMyPlayer()) return;

	CBlob@ b = player.getBlob();
	if (b !is null)
	{
		const u32 gameTime = getGameTime();
		const string name = getRecieverName(b);
		const s32 next_items = getMatsTime(this, name);
		if (next_items > gameTime)
		{
			string action = (name == "builder" ? "Go Build" : "Go Fight");
			if (this.get_u16("day_number") < 2)
			{
				action = "Prepare for Battle";
			}

			const u32 secs = ((next_items - 1 - gameTime) / getTicksASecond()) + 1;
			const string units = ((secs != 1) ? " seconds" : " second");
			GUI::SetFont("menu");
			GUI::DrawTextCentered(getTranslatedString("Next resupply in {SEC}{TIMESUFFIX}, {ACTION}!")
							.replace("{SEC}", "" + secs)
							.replace("{TIMESUFFIX}", getTranslatedString(units))
							.replace("{ACTION}", getTranslatedString(action)),
			              Vec2f(getScreenWidth() / 2, getScreenHeight() / 3 - 70.0f + Maths::Sin(gameTime / 3.0f) * 5.0f),
			              SColor(255, 255, 55, 55));
		}
	}
}
