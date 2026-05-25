//Enchanter
//Gingerbeard @ March 30, 2026

#include "ParticleTeleport.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_BestiaryCommon.as"
#include "Zombie_Translation.as"
#include "RequirementsCustom.as"
#include "EnchanterCommon.as"
#include "EquipmentCommon.as"
#include "ParticleMagic.as"

const int total_enchant_time = 90;
const u8 stay_minutes = 6;

const int max_enchants = 3;

u32 last_talk = 0;
const u32 voice_delay = 30 * 3;

void onInit(CBlob@ this)
{
	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.server_setTeamNum(0);

	Bestiary::client_Unlock("enchanter");

	ParticleTeleport(this.getPosition());

	this.SetLight(true);
	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 150, 240, 171));
	
	this.SetMinimapOutsideBehaviour(CBlob::minimap_none);
	this.SetMinimapVars("PartyIndicator.png", 0, Vec2f(16, 16));
	this.SetMinimapRenderAlways(true);

	this.addCommandID("server_give_payment");
	this.addCommandID("client_give_payment");
	this.addCommandID("server_assess_item");
	this.addCommandID("client_assess_item");
	this.addCommandID("server_enchant_item");
	this.addCommandID("client_enchant_item");
	this.addCommandID("client_random_enchant_item");
	this.addCommandID("client_on_attempt_crated");
	this.addCommandID("client_teleport");

	Random seed(this.getNetworkID());

	const u8 worth = 5; // one enchant is worth this many players
	const int random_factor = XORRandom(7) - 3;
	const u8 player_count = Maths::Max(getRules().get_u8("survivor player count") - worth + random_factor, 1);
	const u8 enchants_per_player = Maths::Floor(player_count / worth);
	const u8 enchants_count = 1 + Maths::Min(enchants_per_player, max_enchants - 1);
	this.set_u8("enchants_count", enchants_count);

	CBitStream reqs;
	SetupPayment(@reqs, enchants_count, seed);
	this.set("enchanter_requirements", reqs);

	AddColorToken("$BLUE$", SColor(255, 80, 160, 255));

	this.set_u32("time till departure", getGameTime() + getTicksASecond() * 60 * stay_minutes);

	SetupEnchants(this);

	last_talk = 0;
}

void onDie(CBlob@ this)
{
	ParticleTeleport(this.getPosition());
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CShape@ shape = blob.getShape();
	return shape !is null && shape.isStatic() && shape.getConsts().collidable;
}

void onTick(CBlob@ this)
{
	HandleDeparture(this);

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("ENCHANT");
	if (point is null) return;

	CBlob@ item = point.getOccupied();
	if (item is null)
	{
		point.offset = Vec2f_zero;
		this.set_u32("enchanting_time", 0);
		return;
	}

	item.SetFacingLeft(true);

	Vec2f pos = this.getPosition();
	Vec2f end = this.getPosition() + Vec2f(0, -40);
	getMap().rayCastSolid(pos, end, end);
	end -= this.getPosition() - Vec2f(0, 8);

	const u32 enchanting_time = this.get_u32("enchanting_time");
	if (enchanting_time > 0)
	{
		if (enchanting_time > 20)
		{
			const f32 amplitude = 0.5f;
			const f32 speed = 0.3f;
			f32 x = (Maths::Sin(getGameTime() * speed) + (XORRandom(100)/100.0f - 0.5f)) * amplitude;
			f32 y = (Maths::Cos(getGameTime() * speed) + (XORRandom(100)/100.0f - 0.5f)) * amplitude;
			point.offset = Vec2f_lerp(point.offset, Vec2f(x, end.y + y), 0.65f);

			ParticleEnergyVortex(pos + point.offset);
		}
		else if (enchanting_time == 20)
		{
			ParticlesFinishEnchant(this, item);

			server_CompleteEnchantment(this, item);
		}
		else if (enchanting_time == 1)
		{
			item.server_DetachAll();
		}

		this.Untag("assessment_menu");
		this.set_u32("enchanting_time", enchanting_time - 1);
	}
	else
	{
		const f32 y = end.y + Maths::Sin(getGameTime() * 0.05f) * 4.0f;
		point.offset = Vec2f_lerp(point.offset, Vec2f(0, y), 0.5f);
	}
}

void HandleDeparture(CBlob@ this)
{
	const u32 gameTime = getGameTime();
	const u32 timeTillLeave = this.get_u32("time till departure");

	if (gameTime == timeTillLeave - 200 && isClient())
	{
		if (!hasEnchants(this))
		{
			Chat(this, Translate("Enchanter7"));
		}
		else if (this.hasTag("enchanter_paid"))
		{
			Chat(this, Translate("Enchanter6"));
		}
		else
		{
			Chat(this, Translate("Enchanter5"));
		}
	}

	if (gameTime >= timeTillLeave && isServer())
	{
		if (hasEnchants(this) && this.hasTag("enchanter_paid"))
		{
			server_RandomEnchant(this);
		}
		this.server_Die();
	}
}

void ParticlesFinishEnchant(CBlob@ this, CBlob@ item)
{
	if (!isClient()) return;

	item.getSprite().PlaySound("EnchantComplete.ogg");

	Vec2f pos = item.getPosition();
	for (int i = 0; i < 24; i++)
	{
		const f32 angle = (360.0f / 24) * i * 3.14159f / 180.0f;
		Vec2f spawnPos = pos + Vec2f(Maths::Cos(angle), Maths::Sin(angle)) * 16.0f;
		Vec2f dir = pos - spawnPos;
		dir.Normalize();

		Vec2f perp(-dir.y, dir.x);
		Vec2f vel = dir * 4.0f + perp * 0.8f;

		const u8 c = 220 + XORRandom(36);
		SColor col(255, c, c, c);
		CParticle@ p = ParticlePixelUnlimited(spawnPos, vel, col, true);
		if (p !is null)
		{
			p.timeout = 25;
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.damping = 0.92f;
		}
	}
}

void server_CompleteEnchantment(CBlob@ this, CBlob@ item)
{
	if (!isServer()) return;

	CBlob@ result = server_MakeEnchantedItem(this, item);
	if (result is null) return;

	item.server_Die();
	this.server_AttachTo(result, "ENCHANT");

	const u8 enchants_count = Maths::Max(0, this.get_u8("enchants_count") - 1);
	this.set_u8("enchants_count", enchants_count);
	this.Sync("enchants_count", true);

	if (enchants_count == 0)
	{
		this.set_u32("time till departure", getGameTime() + 270);
		this.Sync("time till departure", true);
	}
}

void server_RandomEnchant(CBlob@ this)
{
	if (!isServer()) return;

	dictionary@ enchants;
	if (!this.get("enchants", @enchants)) return;

	CBlob@[] blobs;
	getBlobs(@blobs);

	CBlob@[] enchantable;
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		if (enchants.exists(getEnchantKey(b)))
		{
			enchantable.push_back(b);
		}
	}

	const u8 enchants_count = this.get_u8("enchants_count");
	for (int i = 0; i < enchants_count; i++)
	{
		if (enchantable.length <= 0) continue;

		const int index = XORRandom(enchantable.length);
		CBlob@ item = enchantable[index];

		enchantable.erase(index);

		CBlob@ result = server_MakeEnchantedItem(this, item);
		if (result is null) return;

		bool equipped = false;
		if (item.exists("equipper_id"))
		{
			CBlob@ equipper = getBlobByNetworkID(item.get_netid("equipper_id"));
			if (equipper !is null)
			{
				server_EquipBlob(equipper, result);
				equipped = true;
			}
		}

		CBlob@ inventory_blob = item.getInventoryBlob();
		if (!equipped && inventory_blob !is null)
		{
			item.server_RemoveFromInventories();
			inventory_blob.server_PutInInventory(result);
		}

		CBitStream stream;
		stream.write_netid(result.getNetworkID());
		this.SendCommand(this.getCommandID("client_random_enchant_item"), stream);

		item.server_Die();
	}
}


/// BUTTONS

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 60.0f) return;

	if (isEnchanting(this) || !hasEnchants(this)) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("ENCHANT");
	if (point is null) return;

	if (point.getOccupied() !is null)
	{
		EnchantButton(this, caller);
	}
	else if (!this.hasTag("enchanter_paid"))
	{
		PaymentButton(this, caller);
	}
	else
	{
		AssessButton(this, caller);
	}
}

void PaymentButton(CBlob@ this, CBlob@ caller)
{
	const bool has_reqs = hasEnchanterRequirements(this, caller);
	const u8 icon_num = has_reqs ? 26 : 14;
	const string description = has_reqs ? Translate("EnchantGUI0") : Translate("Help");
	CButton@ button = caller.CreateGenericButton(icon_num, Vec2f(0, 0), this, AttemptPayment, description);
}

void AssessButton(CBlob@ this, CBlob@ caller)
{
	CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, this.getCommandID("server_assess_item"), Translate("EnchantGUI1"));
	if (button is null) return;

	CBlob@ carried = caller.getCarriedBlob();
	button.SetEnabled(carried !is null && !carried.hasTag("temp blob"));
}

void EnchantButton(CBlob@ this, CBlob@ caller)
{
	if (this.hasTag("assessment_menu")) return;

	CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, OpenEnchantMenu, Translate("EnchantGUI1"));
}

void AttemptPayment(CBlob@ this, CBlob@ caller)
{
	if (!hasEnchanterRequirements(this, caller))
	{
		const string[] chats = { Translate("Enchanter0"), Translate("Enchanter8"), Translate("Enchanter9") };
		Chat(this, chats[XORRandom(chats.length)]);
		return;
	}
	
	this.SendCommand(this.getCommandID("server_give_payment"));
}

void OpenEnchantMenu(CBlob@ this, CBlob@ caller)
{
	this.Tag("assessment_menu");
}


/// HELPER FUNCS

void Chat(CBlob@ this, const string&in text)
{
	this.Chat(text);

	if (getGameTime() > last_talk + voice_delay)
	{
		last_talk = getGameTime();
		this.getSprite().PlaySound("Enchanter"+XORRandom(2), 1.2f, 1.0f);
	}
}

bool hasEnchanterRequirements(CBlob@ this, CBlob@ caller)
{
	CBitStream@ reqs;
	if (!this.get("enchanter_requirements", @reqs)) return false;

	return hasRequirements(getRequirementBlobs(caller), reqs);
}

bool hasEnchants(CBlob@ this)
{
	return this.get_u8("enchants_count") > 0;
}

bool isEnchanting(CBlob@ this)
{
	return this.get_u32("enchanting_time") > 0;
}


/// COMMANDS

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_give_payment") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		CBitStream@ reqs;
		if (!this.get("enchanter_requirements", @reqs)) return;
		
		if (this.hasTag("enchanter_paid")) return;

		CBlob@[]@ blobs = getRequirementBlobs(caller);
		if (!hasRequirements(blobs, reqs)) return;

		CBlob@[] used;
		server_TakeRequirements(blobs, reqs, used);

		this.Tag("enchanter_paid");

		CBitStream stream;
		stream.write_s32(used.length);
		for (int i = 0; i < used.length; i++)
		{
			stream.write_netid(used[i].getNetworkID());
		}

		this.SendCommand(this.getCommandID("client_give_payment"), stream);
	}
	else if (cmd == this.getCommandID("client_give_payment") && isClient())
	{
		this.getSprite().PlaySound("snes_coin.ogg");
		this.Tag("enchanter_paid");

		const string[] chats = { Translate("Enchanter1"), Translate("Enchanter10") };
		Chat(this, chats[XORRandom(chats.length)]);

		int used_length;
		if (!params.saferead_s32(used_length)) return;

		for (int i = 0; i < used_length; i++)
		{
			u16 netid;
			if (!params.saferead_netid(netid)) return;

			CBlob@ blob = getBlobByNetworkID(netid);
			if (blob is null || blob.isInInventory()) continue;

			if (blob.hasTag("player") && !blob.hasTag("undead") && !blob.hasTag("dead"))
			{
				blob.getSprite().PlaySound("man_scream.ogg");
				ParticleAnimated("spirit.png", blob.getPosition(), Vec2f(0, -0.25), 0, 1.0f, 8, 0.0f, true);
			}
			else
			{
				CParticle@ p = ParticleAnimated("MediumSteam", blob.getPosition(), Vec2f_zero, 0, 1.0f, 2 + XORRandom(3), -0.1f, true);
				if (p !is null) p.Z = 650.0f;
			}

			blob.getSprite().Gib();
		}
	}
	else if (cmd == this.getCommandID("server_assess_item") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		CBlob@ item = caller.getCarriedBlob();
		if (item is null) return;
		
		if (!hasEnchants(this)) return;

		if (isEnchantable(this, item))
		{
			item.server_DetachAll();
			this.server_AttachTo(item, "ENCHANT");
		}

		CBitStream stream;
		stream.write_netid(caller.getNetworkID());
		stream.write_netid(item.getNetworkID());
		this.SendCommand(this.getCommandID("client_assess_item"), stream);
	}
	else if (cmd == this.getCommandID("client_assess_item") && isClient())
	{
		u16 caller_netid, item_netid;
		if (!params.saferead_netid(caller_netid)) return;
		if (!params.saferead_netid(item_netid)) return;

		CBlob@ caller = getBlobByNetworkID(caller_netid);
		if (caller is null) return;

		CBlob@ item = getBlobByNetworkID(item_netid);
		if (item is null) return;

		if (!isEnchantable(this, item))
		{
			const string[] chats = { Translate("Enchanter2"), Translate("Enchanter3"), Translate("Enchanter4") };
			Chat(this, chats[XORRandom(chats.length)]);
			return;
		}

		if (caller.isMyPlayer())
		{
			this.Tag("assessment_menu");
		}
	}
	else if (cmd == this.getCommandID("server_enchant_item") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("ENCHANT");
		if (point is null) return;

		CBlob@ item = point.getOccupied();
		if (item is null) return;

		bool do_enchant;
		if (!params.saferead_bool(do_enchant)) return;

		if (!do_enchant)
		{
			item.server_DetachAll();
			return;
		}

		Statistics::server_Add("items_enchanted", 1, player);

		this.set_u32("enchanting_time", total_enchant_time);

		this.SendCommand(this.getCommandID("client_enchant_item"));
	}
	else if (cmd == this.getCommandID("client_enchant_item") && isClient())
	{
		this.getSprite().PlaySound("EnchantItem0", 2.5f, 0.86f);
		this.set_u32("enchanting_time", total_enchant_time);
	}
	else if (cmd == this.getCommandID("client_random_enchant_item") && isClient())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ item = getBlobByNetworkID(netid);
		if (item is null) return;

		ParticlesFinishEnchant(this, item);
	}
	else if (cmd == this.getCommandID("client_on_attempt_crated") && isClient())
	{
		Chat(this, Translate("Enchanter11"));
	}
	else if (cmd == this.getCommandID("client_teleport") && isClient())
	{
		Vec2f old_pos, new_pos;
		if (!params.saferead_Vec2f(old_pos)) { error("Failed to read old_pos [Enchanter]"); return; }
		if (!params.saferead_Vec2f(new_pos)) { error("Failed to read new_pos [Enchanter]"); return; }

		this.setPosition(new_pos);

		ParticleTeleport(old_pos);
		ParticleTeleportSparks(old_pos, new_pos);
		ParticleTeleport(new_pos);
	}
}


/// NETWORK

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	CBitStream@ reqs;
	if (!this.get("enchanter_requirements", @reqs)) return;

	stream.write_CBitStream(reqs);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	CBitStream reqs;
	if (!stream.saferead_CBitStream(reqs)) return false;

	this.set("enchanter_requirements", reqs);

	return true;
}
