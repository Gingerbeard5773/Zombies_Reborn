//Auto-mining quarry
//converts wood into ores

#include "GenericButtonCommon.as"

const string[] fuel_names = {"mat_coal", "mat_wood"};
const int[] fuel_strength = { 3, 1 };

//balance
const int input = 100;					// input cost in fuel
const int initial_output = 80;			// output amount in ore
const int conversion_frequency = 30;	// how often to convert, in seconds

const int min_input = Maths::Ceil(input / initial_output);

//fuel levels for animation
const int max_fuel = 500;
const int mid_fuel = 300;
const int low_fuel = 150;

//property names
const string fuel_prop = "fuel_level";

void onInit(CSprite@ this)
{
	CSpriteLayer@ belt = this.addSpriteLayer("belt", "QuarryBelt.png", 32, 32);
	if (belt !is null)
	{
		//default anim
		{
			Animation@ anim = belt.addAnimation("default", 0, true);
			int[] frames = {
				0, 1, 2, 3,
				4, 5, 6, 7,
				8, 9, 10, 11,
				12, 13
			};
			anim.AddFrames(frames);
		}
		//belt setup
		belt.SetOffset(Vec2f(-7.0f, -4.0f));
		belt.SetRelativeZ(1);
		belt.SetVisible(true);
	}

	CSpriteLayer@ wood = this.addSpriteLayer("wood", "Quarry.png", 16, 16);
	if (wood !is null)
	{
		wood.SetOffset(Vec2f(8.0f, -1.0f));
		wood.SetVisible(false);
		wood.SetRelativeZ(1);
	}

	this.SetEmitSound("/Quarry.ogg");
	this.SetEmitSoundPaused(true);
}

void onInit(CBlob@ this)
{
	//building properties
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50);
	this.getShape().getConsts().mapCollisions = false;

	//gold building properties
	this.set_s32("gold building amount", 100);

	//quarry properties
	this.set_s16(fuel_prop, 0);

	//commands
	this.addCommandID("add fuel");
}

void onTick(CBlob@ this)
{
	//only do "real" update logic on server
	const int blobCount = this.get_s16(fuel_prop);
	if (isServer() && blobCount >= min_input)
	{
		//only convert every conversion_frequency seconds
		if ((getGameTime() + this.getNetworkID()) % (conversion_frequency * 30) == 0)
		{
			server_spawnOre(this);
		}
	}
}

void onTick(CSprite@ this)
{
	const int fuel = this.getBlob().get_s16(fuel_prop);
	this.SetEmitSoundPaused(fuel <= 0);

	CSpriteLayer@ layer = this.getSpriteLayer("wood");
	if (layer !is null)
	{
		if (fuel < min_input)
		{
			layer.SetVisible(false);
		}
		else
		{
			layer.SetVisible(true);
			int frame = 5;
			if (fuel > low_fuel) frame = 6;
			if (fuel > mid_fuel) frame = 7;
			layer.SetFrameIndex(frame);
		}
	}

	if (getGameTime() % 15 == 0)
	{
		CSpriteLayer@ belt = this.getSpriteLayer("belt");
		if (belt is null) return;

		Animation@ anim = belt.getAnimation("default");
		if (anim is null) return;

		//modify it based on activity
		if (fuel > 0)
		{
			// slowly start animation
			if (anim.time == 0) anim.time = 6;
			if (anim.time > 3) anim.time--;
		}
		else
		{
			//(not tossing stone)
			if (anim.frame < 2 || anim.frame > 8)
			{
				// slowly stop animation
				if (anim.time == 6) anim.time = 0;
				if (anim.time > 0 && anim.time < 6) anim.time++;
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.get_s16(fuel_prop) >= max_fuel) return;

	for (uint i = 0; i < fuel_names.length; i++)
	{
		const string name = fuel_names[i];
		if (caller.hasBlob(name, 1))
		{
			CBitStream params;
			params.write_u8(i);
			CButton@ button = caller.CreateGenericButton("$"+name+"$", Vec2f(), this, this.getCommandID("add fuel"), getTranslatedString("Add fuel (Wood or Coal)"), params);
			if (button !is null)
			{
				button.deleteAfterClick = false;
			}
			return;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add fuel") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		const int requestedAmount = Maths::Min(250, max_fuel - this.get_s16(fuel_prop));
		if (requestedAmount <= 0) return;
		
		const u8 index = params.read_u8();
		const string fuel_name = fuel_names[index];
		const int fuel_amount = fuel_strength[index];

		CBlob@ carried = caller.getCarriedBlob();
		const int callerQuantity = caller.getInventory().getCount(fuel_name) + (carried !is null && carried.getName() == fuel_name ? carried.getQuantity() : 0);
		const int amountToStore = Maths::Min(requestedAmount, callerQuantity);
		if (amountToStore > 0)
		{
			caller.TakeBlob(fuel_name, amountToStore);
			this.set_s16(fuel_prop, this.get_s16(fuel_prop) + amountToStore*fuel_amount);
			this.Sync(fuel_prop, true);
		}
	}
}

void server_spawnOre(CBlob@ this)
{
	CBlob@ stone = server_CreateBlobNoInit("mat_stone");
	if (stone is null) return;

	const int blobCount = this.get_s16(fuel_prop);
	int actual_input = Maths::Min(input, blobCount);
	int amountToSpawn = Maths::Floor(initial_output * actual_input / input);
	//round to 5
	int remainder = amountToSpawn % 5;
	amountToSpawn += (remainder < 3 ? -remainder : (5 - remainder));

	stone.Tag("custom quantity");
	stone.setPosition(this.getPosition() + Vec2f(-8.0f, 0.0f));
	stone.server_SetQuantity(amountToSpawn);
	stone.Init();

	this.set_s16(fuel_prop, blobCount - actual_input); //burn fuel
	this.Sync(fuel_prop, true);
}
