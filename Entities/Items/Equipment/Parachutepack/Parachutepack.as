#include "EquipmentCommon.as";
#include "RunnerTextures.as";
#include "Zombie_Translation.as";

const u32 parachute_delay = 3*30; //3 secs

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "torso");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack
	
	this.addCommandID("server_open_parachute");
	this.addCommandID("client_open_parachute");

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);
	addOnClientJoin(this, @onClientJoin);
	
	AddIconToken("$opaque_heatbar$", "Entities/Industry/Drill/HeatBar.png", Vec2f(24, 6), 0);
	AddIconToken("$parachutepack$", "Parachutepack.png", Vec2f(16, 16), 1, 0);
	
	this.setInventoryName(name(Translate::Parachutepack));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	this.set_netid("equipper_id", equipper.getNetworkID());
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.getSprite().RemoveSpriteLayer("backpack");

	RemoveParachute(this, equipper);
	
	this.set_netid("equipper_id", 0);
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	const bool canRemoveParachute = equipper.isOnGround() || equipper.isInWater() || equipper.isAttached() || equipper.isOnLadder();
	if (this.hasTag("parachute"))
	{
		OpenParachute(this, equipper);

		Vec2f vel = equipper.getVelocity();
		equipper.setVelocity(Vec2f(vel.x, vel.y * 0.8f));

		if (canRemoveParachute)
			RemoveParachute(this, equipper);

		return;
	}

	if (equipper.isMyPlayer() && !canRemoveParachute)
	{
		CControls@ controls = getControls();
		if (controls.isKeyJustPressed(KEY_LSHIFT) && getGameTime() >= this.get_u32("next_parachute"))
		{
			this.Tag("parachute");
			this.SendCommand(this.getCommandID("server_open_parachute"));
		}
	}
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ backpack = equipper_sprite.getSpriteLayer("backpack");
	if (backpack is null)
	{
		//add backpack spritelayer. done in onTick because KAG ENGINE IS FUCKING SHIT AND CANT SYNC NEW CLIENTS PROPERLY.
		@backpack = equipper_sprite.addSpriteLayer("backpack", "Parachutepack.png", 16, 16);
		if (backpack !is null)
		{
			backpack.SetVisible(true);
			backpack.SetRelativeZ(-2);
			backpack.SetOffset(Vec2f(4, -2));

			if (equipper_sprite.isFacingLeft())
				backpack.SetFacingLeft(true);
		}
	}
	if (backpack !is null)
	{
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, 0);
       
		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(4, 2);
		backpack.SetOffset(headoffset);
		backpack.SetVisible(!this.hasTag("parachute"));
	}
}

void onClientJoin(CBlob@ this, CBlob@ equipper)
{
	OnEquip(this, equipper);
}

void OpenParachute(CBlob@ this, CBlob@ equipper)
{
	CSprite@ sprite = equipper.getSprite();
	if (sprite.getSpriteLayer("parachute") !is null) return;

	CSpriteLayer@ chute = sprite.addSpriteLayer("parachute", "Crate.png", 32, 32);
	if (chute !is null)
	{
		Animation@ anim = chute.addAnimation("default", 0, true);
		anim.AddFrame(4);
		chute.SetOffset(Vec2f(0.0f, - 17.0f));
		sprite.PlaySound("GetInVehicle");
	}
}

void RemoveParachute(CBlob@ this, CBlob@ equipper)
{
	this.Untag("parachute");
	
	if (equipper.isMyPlayer())
	{
		this.set_u32("next_parachute", getGameTime() + parachute_delay);
	}

	CSprite@ sprite = equipper.getSprite();
	CSpriteLayer@ chute = sprite.getSpriteLayer("parachute");
	if (chute !is null)
	{
		ParticlesFromSprite(chute);
		sprite.PlaySound("join");
		sprite.RemoveSpriteLayer("parachute");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_open_parachute") && isServer())
	{
		this.Tag("parachute");
		this.SendCommand(this.getCommandID("client_open_parachute"));
	}
	else if (cmd == this.getCommandID("client_open_parachute") && isClient())
	{
		this.Tag("parachute");
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.exists("equipper_id")) return;

	const u16 equipper_id = blob.get_netid("equipper_id");
	if (equipper_id <= 0) return;
	
	CBlob@ equipper = getBlobByNetworkID(equipper_id);
	if (equipper is null || !equipper.isMyPlayer()) return;
	
	const u32 next_parachute = blob.get_u32("next_parachute");
	if (next_parachute <= getGameTime()) return;
	
	const u32 time = getGameTime() - (next_parachute - parachute_delay);
	const f32 percentage = f32(time) / f32(parachute_delay);

	Vec2f pos = equipper.getInterpolatedScreenPos() + Vec2f(-22, 16);
	Vec2f dimension = Vec2f(42, 4);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	GUI::DrawIconByName("$opaque_heatbar$", pos);
	GUI::DrawRectangle(pos + Vec2f(4, 4), bar + Vec2f(4, 4), SColor(255, 28, 2, 130));
	GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 4), SColor(255, 30, 51, 158));
	GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 2), SColor(255, 55, 55, 198));
}
