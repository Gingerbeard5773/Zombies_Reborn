// scroll script that duplicates an object completely

#include "GenericButtonCommon.as";
#include "MakeScroll.as";
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, Translate::ScrollClone);
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
		CBlob@ aimBlob = getBlobByNetworkID(params.read_netid());
		if (aimBlob is null) return;
		
		if (this.hasTag("dead")) return;
		this.Tag("dead");

		CBlob@ clone = server_CreateClone(aimBlob, this.getPosition() + Vec2f(0, (this.getHeight() - aimBlob.getHeight()) / 2 + 4));
		copyInventory(aimBlob, clone);
		this.server_Die();
	}
}

void copyInventory(CBlob@ blob, CBlob@ clone)
{
	CInventory@ inv = blob.getInventory();
	if (inv is null) return;
	
	const u8 count = inv.getItemsCount();
	for (u8 i = 0; i < count; i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item is null) continue;
		
		CBlob@ cloneItem = server_CreateClone(item, clone.getPosition());
		clone.server_PutInInventory(cloneItem);
	}
}

CBlob@ server_CreateClone(CBlob@ blob, Vec2f pos)
{
	//special cases
	const string name = blob.getName();
	if (name == "scroll")
	{
		string scrollType = blob.get_string("scroll defname0");
		if (scrollType == "clone") scrollType = "royalty"; //no infinite dupes!
		
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
