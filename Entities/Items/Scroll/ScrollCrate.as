// scroll script that puts any item into a crate

#include "GenericButtonCommon.as";
#include "MakeCrate.as";
#include "Zombie_Translation.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, desc(Translate::ScrollCrate));
}

void Callback_Spell(CBlob@ this, CBlob@ caller)
{
	CBlob@ aimBlob = getMap().getBlobAtPosition(caller.getAimPos());
	if (aimBlob is null || !canCrate(aimBlob)) return;
	
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
		
		if (this.hasTag("dead")) return;
		this.Tag("dead");

		string name = aimBlob.getName();
		if (name == "skelepedebody") name = "skelepede";

		CBlob@ crate = server_MakeCrate(name, aimBlob.getInventoryName(), 0, aimBlob.getTeamNum(), aimBlob.getPosition());
		CShape@ shape = aimBlob.getShape();
		crate.set_Vec2f("required space", Vec2f(Maths::Ceil(shape.getWidth()/8), Maths::Ceil(shape.getHeight()/8)));
		aimBlob.server_Die();
		this.server_Die();
	}
}

const bool canCrate(CBlob@ blob)
{
	const string name = blob.getName();
	return name != "scroll" && name != "crate" && name != "library" && blob.getPlayer() is null;
}

void onDie(CBlob@ this)
{
	Sound::Play("MagicWand.ogg", this.getPosition());
}
