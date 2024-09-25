// scroll script that makes enemies insta gib within some radius

#include "Hitters.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_netid(caller.getNetworkID());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), getTranslatedString("Use this to make all visible enemies instantly turn into a pile of gibs."), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;

		Vec2f pos = this.getPosition();

		bool hit = false;
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller !is null)
		{
			const u8 team = caller.getTeamNum();
			CBlob@[] blobsInRadius;
			if (getMap().getBlobsInRadius(pos, 500.0f, @blobsInRadius))
			{
				const u16 blobsLength = blobsInRadius.length;
				for (u16 i = 0; i < blobsLength; i++)
				{
					CBlob@ b = blobsInRadius[i];
					if (b.getTeamNum() != team && b.hasTag("undead"))
					{
						ParticleZombieLightning(b.getPosition());
						if (isServer())
							caller.server_Hit(b, pos, Vec2f(0, 0), 10.0f, Hitters::suddengib, true);
						hit = true;
					}
				}
			}
		}

		if (hit)
		{
			this.Tag("dead");
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	ParticleZombieLightning(this.getPosition());
	Sound::Play("SuddenGib.ogg");
}