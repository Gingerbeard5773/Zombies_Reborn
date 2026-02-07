// scroll script that duplicates an object completely

#include "GenericButtonCommon.as"
#include "MakeScroll.as"
#include "MakeSeed.as"
#include "MakeCrate.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, desc(Translate::ScrollClone));
}

void Callback_Spell(CBlob@ this, CBlob@ caller)
{
	CBlob@ aimBlob = getMap().getBlobAtPosition(caller.getAimPos());
	if (aimBlob is null || aimBlob is this || !canClone(aimBlob)) return;

	CBitStream params;
	params.write_netid(aimBlob.getNetworkID());
	this.SendCommand(this.getCommandID("server_execute_spell"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ aimBlob = getBlobByNetworkID(netid);
		if (aimBlob is null) return;

		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (this.hasTag("dead")) return;
		this.Tag("dead");

		Statistics::server_Add("scrolls_used", 1, player);

		Vec2f pos = this.getPosition() + Vec2f(0, (this.getHeight() - aimBlob.getHeight()) / 2 + 4);
		CBlob@ clone = server_CreateClone(aimBlob, pos, player);
		copyInventory(aimBlob, clone, player);

		if (clone.getName() == "library")
		{
			Achievement::server_Unlock(Achievement::GreatAwakening, player);
		}

		this.server_Die();
	}
}

void copyInventory(CBlob@ blob, CBlob@ clone, CPlayer@ player)
{
	CInventory@ inv = blob.getInventory();
	if (inv is null) return;
	
	const u16 count = inv.getItemsCount();
	for (u16 i = 0; i < count; i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item is null) continue;
		
		CBlob@ cloneItem = server_CreateClone(item, clone.getPosition(), player);
		clone.server_PutInInventory(cloneItem);
	}
}

CBlob@ server_CreateClone(CBlob@ blob, Vec2f pos, CPlayer@ player)
{
	//special cases
	const string name = blob.getName();
	if (name == "scroll")
	{
		string scrollType = blob.get_string("scroll defname0");
		if (scrollType == "clone")
		{
			Achievement::server_Unlock(Achievement::WorthATry, player);
			scrollType = "royalty"; //no infinite dupes!
		}
		
		CBlob@ scroll = server_MakePredefinedScroll(pos, scrollType);
		return scroll;
	}
	else if (name == "seed")
	{
		CBlob@ seed = server_MakeSeed(pos, blob.get_string("seed_grow_blobname"));
		return seed;
	}
	else if (name == "crate" && blob.exists("packed"))
	{
		CBlob@ crate = server_MakeCrate(blob.get_string("packed"), blob.get_string("packed name"), blob.get_u8("frame"), blob.getTeamNum(), pos);
		return crate;
	}
	
	//normal duplication
	CBlob@ clone = server_CreateBlob(name, blob.getTeamNum(), pos);
	clone.server_SetQuantity(blob.getQuantity());
	return clone;
}

const bool canClone(CBlob@ blob)
{
	return (!blob.hasTag("invincible") || !blob.getShape().isStatic()) && blob.getPlayer() is null;
}

void onDie(CBlob@ this)
{
	Sound::Play("MagicWand.ogg", this.getPosition());
}
