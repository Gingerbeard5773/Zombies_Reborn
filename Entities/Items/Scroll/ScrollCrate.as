// scroll script that puts any item into a crate

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";
#include "MakeCrate.as";

void onInit(CBlob@ this)
{
	this.addCommandID("put in crate");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	CBitStream params;
	params.write_Vec2f(caller.getAimPos());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("put in crate"), ZombieDesc::scroll_crate, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("put in crate"))
	{
		Vec2f aim = params.read_Vec2f();
		
		CBlob@ aimBlob = getMap().getBlobAtPosition(aim);
		if (aimBlob is null || !canCrate(aimBlob)) return;
		
		if (isClient())
		{
			//effects
			ParticlesFromSprite(aimBlob.getSprite(), aim, Vec2f(0, -1), 1, 1);
			Sound::Play("MagicWand.ogg", aim);
		}
		
		if (isServer())
		{
			CBlob@ crate = server_MakeCrate(aimBlob.getName(), "Crate with "+aimBlob.getInventoryName(), 0, aimBlob.getTeamNum(), aim);
			CShape@ shape = aimBlob.getShape();
			crate.set_Vec2f("required space", Vec2f(Maths::Ceil(shape.getWidth()/8), Maths::Ceil(shape.getHeight()/8)));
			aimBlob.server_Die();
			this.server_Die();
		}
	}
}

const bool canCrate(CBlob@ blob)
{
	const string name = blob.getName();
	return !blob.hasTag("invincible") && name != "scroll" && name != "crate" && blob.getPlayer() is null;
}
