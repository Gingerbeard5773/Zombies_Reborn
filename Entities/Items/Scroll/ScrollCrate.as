// scroll script that puts any item into a crate

#include "GenericButtonCommon.as"
#include "MakeCrate.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, Callback_Spell, desc(Translate("ScrollCrate")));
}

void Callback_Spell(CBlob@ this, CBlob@ caller)
{
	CBlob@ aimBlob = getMap().getBlobAtPosition(caller.getAimPos());
	if (aimBlob is null || !canCrate(caller, aimBlob)) return;
	
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

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		if (this.hasTag("dead")) return;
		this.Tag("dead");

		Statistics::server_Add("scrolls_used", 1, player);

		string name = aimBlob.getName();
		if (name == "skelepedebody") name = "skelepede";
		
		if (name == "sedgwick")
		{
			Achievement::server_Unlock(Achievement::Sealed, player);
		}
		else if (name == "traderbomber")
		{
			Achievement::server_Unlock(Achievement::Kidnapper, player);
		}

		if (name == "enchanter")
		{
			//fun easter egg if you try to crate tim
			PutIntoCrateInventory(caller);

			if (aimBlob.hasCommandID("client_on_attempt_crated"))
			{
				aimBlob.SendCommand(aimBlob.getCommandID("client_on_attempt_crated"));
			}
		}
		else if (aimBlob.hasTag("player") && !aimBlob.hasTag("undead"))
		{
			//players and bots get forced inside a crate
			PutIntoCrateInventory(aimBlob);
		}
		else 
		{
			//otherwise create a crate that can be unpacked
			CBlob@ crate = server_MakeCrate(name, aimBlob.getInventoryName(), 0, aimBlob.getTeamNum(), aimBlob.getPosition());
			CShape@ shape = aimBlob.getShape();
			crate.set_Vec2f("required space", Vec2f(Maths::Ceil(shape.getWidth()/8), Maths::Ceil(shape.getHeight()/8)));
			aimBlob.server_Die();
		}

		this.server_Die();

		this.SendCommand(this.getCommandID("client_execute_spell"));
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Sound::Play("MagicWand.ogg", this.getPosition());
	}
}

const bool canCrate(CBlob@ caller, CBlob@ blob)
{
	if (blob.hasTag("temp blob")) return false;

	if (caller is blob) return false;

	const string name = blob.getName();
	if (name == "library")
	{
		CPlayer@ player = caller.getPlayer();
		if (player !is null && player.isMyPlayer())
		{
			Achievement::client_Unlock(Achievement::NiceTry);
		}
		return false;
	}

	return name != "scroll" && name != "crate";
}

CBlob@ PutIntoCrateInventory(CBlob@ blob)
{
	CBlob@ crate = server_CreateBlob("crate", blob.getTeamNum(), blob.getPosition());
	if (crate !is null)
	{
		crate.server_PutInInventory(blob);
		crate.setVelocity(blob.getVelocity());
	}
	
	return crate;
}
