//Gingerbeard @ July 27, 2024
#include "RunnerCommon.as"
#include "CrossbowCommon.as";

void onInit(CBlob@ this)
{
	// Prevent classes from jabbing n stuff
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null) 
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}
	
	this.addCommandID("shoot arrow client");
	this.addCommandID("shoot arrow server");
	
	this.Tag("gun");
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently
	
	CrossbowInfo crossbow;
	this.set("crossbowInfo", @crossbow);
}

void onTick(CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();
		if (holder !is null)
		{
			CrossbowInfo@ crossbow;
			if (!this.get("crossbowInfo", @crossbow)) return;
			
			this.setAngleDegrees(getAimAngle(this, holder));

			RunnerMoveVars@ moveVars;
			if (!holder.get("moveVars", @moveVars)) return;

			ManageBow(this, holder, point, crossbow, moveVars);
		}
	}
}

void ClientFire(CBlob@ this, CBlob@ holder, const u8&in arrow_type)
{
	Vec2f offset(holder.isFacingLeft() ? 2 : -2, -2);
	
	Vec2f arrowPos = this.getPosition() + offset;
	Vec2f arrowVel = (holder.getAimPos() - arrowPos);
	arrowVel.Normalize();
	arrowVel *= Crossbow::SHOOT_VEL;
	
	CBitStream params;
	params.write_Vec2f(arrowPos);
	params.write_Vec2f(arrowVel);
	params.write_u8(arrow_type);

	this.SendCommand(this.getCommandID("shoot arrow server"), params);
}

CBlob@ CreateArrow(CBlob@ this, CBlob@ holder, Vec2f&in arrowPos, Vec2f&in arrowVel, const u8&in arrowType)
{
	CBlob@ arrow = server_CreateBlobNoInit("arrow");
	if (arrow !is null)
	{
		arrow.set_u8("arrow type", arrowType);
		arrow.SetDamageOwnerPlayer(holder.getPlayer());
		arrow.Init();

		arrow.IgnoreCollisionWhileOverlapped(this);
		arrow.server_setTeamNum(holder.getTeamNum());
		arrow.setPosition(arrowPos);
		arrow.setVelocity(arrowVel);
	}
	return arrow;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	CrossbowInfo@ crossbow;
	if (!this.get("crossbowInfo", @crossbow)) return;

	if (cmd == this.getCommandID("shoot arrow client") && isClient())
	{
		crossbow.loaded = false;
		this.getSprite().PlaySound("FireCrossbow"+(XORRandom(4)+1));
	}
	else if (cmd == this.getCommandID("shoot arrow server") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ holder = player.getBlob();
		if (holder is null) return;

		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;
		u8 arrowType;
		if (!params.saferead_u8(arrowType)) return;

		if (arrowType >= arrowTypeNames.length) return;

		crossbow.arrow_type = arrowType;

		if (crossbow.loaded)
			CreateArrow(this, holder, arrowPos, arrowVel, arrowType);

		crossbow.loaded = false;

		this.SendCommand(this.getCommandID("shoot arrow client"));
	}
}

void ManageBow(CBlob@ this, CBlob@ holder, AttachmentPoint@ point, CrossbowInfo@ crossbow, RunnerMoveVars@ moveVars)
{
	const bool ismyplayer = holder.isMyPlayer();

	CSprite@ sprite = holder.getSprite();
	
	const bool pressed_action1 = point.isKeyPressed(key_action1);
	const bool pressed_action2 = point.isKeyPressed(key_action2);

	if (pressed_action2) //charge bow
	{
		if (crossbow.charge_state < Crossbow::charged)
		{
			//slow down player
			moveVars.walkFactor *= 0.45f;
			moveVars.jumpFactor *= 0.75f;
			moveVars.canVault = false;
			
			this.setAngleDegrees(30 * (this.isFacingLeft() ? -1 : 1));
			
			crossbow.charge_state = Crossbow::charging;
			crossbow.charge_time++;
			
			if (crossbow.charge_time == Crossbow::READY_TIME/3)
			{
				sprite.PlaySound("CrossbowCharge1.ogg");
			}
			if (crossbow.charge_time >= Crossbow::READY_TIME)
			{
				//charging finished
				sprite.PlaySound("LoadingTick"+(XORRandom(2)+1));
				crossbow.charge_state = Crossbow::charged;
				
				CInventory@ inv = holder.getInventory();
				if (inv !is null)
				{
					for (u8 i = 0; i < inv.getItemsCount(); i++)
					{
						CBlob@ item = inv.getItem(i);
						int arrow = arrowTypeNames.find(item.getName());
						if (arrow > -1)
						{
							crossbow.loaded = true;
							crossbow.arrow_type = arrow;
							holder.TakeBlob(arrowTypeNames[arrow], 1);
							break;
						}
					}
				}
			}
		}
	}
	else if (pressed_action1) //fire bow
	{
		if (crossbow.charge_state == Crossbow::charged)
		{
			if (crossbow.loaded)
			{
				//create an arrow
				if (ismyplayer)
					ClientFire(this, holder, crossbow.arrow_type);
			}
			else
			{
				//fired with no projectile
				sprite.PlaySound("BolterFire");
			}
			
			//reset back to default
			crossbow.charge_state = Crossbow::none;
			crossbow.charge_time = 0;
		}
	}
	else
	{
		//reset to normal if no actions in progress
		if (crossbow.charge_state < Crossbow::charged)
		{
			crossbow.charge_state = Crossbow::none;
			crossbow.charge_time = Maths::Max(crossbow.charge_time - 4, 0);
		}
	}

	if (ismyplayer)
	{
		//set cursor
		int frame = 0;
		if (crossbow.charge_state == Crossbow::charged)
		{
			//fully charged
			frame = 18;
		}
		else if (crossbow.charge_time > 0)
		{
			//while charging
			frame = int((float(crossbow.charge_time) / float(Crossbow::READY_TIME)) * 9) * 2;
		}
		this.set_u8("frame", frame);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!attached.hasTag("weapon cursor") && attached.hasTag("player"))
	{
		attached.getSprite().AddScript("WeaponCursor.as");
		attached.Tag("weapon cursor");
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ params)
{
	CrossbowInfo@ crossbow;
	if (!this.get("crossbowInfo", @crossbow)) return;

	params.write_s8(crossbow.charge_time);
	params.write_u8(crossbow.charge_state);
	params.write_u8(crossbow.arrow_type);
	params.write_bool(crossbow.loaded);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ params)
{
	CrossbowInfo@ crossbow;
	if (!this.get("crossbowInfo", @crossbow)) return false;
	
	if (!params.saferead_s8(crossbow.charge_time)) return false;
	if (!params.saferead_u8(crossbow.charge_state)) return false;
	if (!params.saferead_u8(crossbow.arrow_type)) return false;
	if (!params.saferead_bool(crossbow.loaded)) return false;

	return true;
}
