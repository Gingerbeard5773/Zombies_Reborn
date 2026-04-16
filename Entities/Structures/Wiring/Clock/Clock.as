// Clock
// Gingerbeard @ April 15, 2026

#include "MechanismsCommon.as"
#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"

const u8 hours_count = 10;

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	bool[] hours_activated(hours_count);
	this.set("hours_activated", hours_activated);

	this.getCurrentScript().tickFrequency = 30;

	this.addCommandID("server_sethour");
	this.addCommandID("client_sethour");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Component component(position);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                          // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_SOURCE,                        // information
		0,                                  // power
		0);                                 // id
	}
}

void onInit(CSprite@ this)
{
	this.SetFacingLeft(false);
	this.SetZ(-50);

	{
		CSpriteLayer@ hand = this.addSpriteLayer("minute_hand", "Clock.png", 1, 5);
		hand.addAnimation("default", 0, false);
		hand.animation.AddFrame(19);
		hand.SetRelativeZ(1);
		hand.SetOffset(Vec2f(-0.5f, -6.5f));
	}
	{
		CSpriteLayer@ hand = this.addSpriteLayer("hour_hand", "Clock.png", 1, 3);
		hand.addAnimation("default", 0, false);
		hand.animation.AddFrame(17);
		hand.SetRelativeZ(1);
		hand.SetOffset(Vec2f(-0.5f, -6.5f));
	}
}

void onTick(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = getRules().daycycle_speed * 3;

	const f32 daytime = getMap().getDayTime();

	CSpriteLayer@ hour = this.getSpriteLayer("hour_hand"); 
	if (hour !is null)
	{
		const f32 angle = daytime * 360.0f;
		hour.ResetTransform();
		hour.RotateBy(angle, Vec2f_zero);
	}

	CSpriteLayer@ minute = this.getSpriteLayer("minute_hand"); 
	if (minute !is null)
	{
		const f32 minute_angle = daytime * 360.0f * 10.0f;
		minute.ResetTransform();
		minute.RotateBy(minute_angle, Vec2f_zero);
	}
}

void onRender(CSprite@ this)
{
	CPlayer@ localplayer = getLocalPlayer();
	if (localplayer is null) return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouse = getControls().getMouseWorldPos();
	const f32 radius = (blob.getRadius()) * 1.50f;
	const bool mouse_on_blob = (mouse - center).getLength() < radius;
	if (mouse_on_blob)
	{
		GUI::SetFont("menu");
		GUI::DrawTextCentered(getTimeString(), blob.getScreenPos() - Vec2f(0, 32), color_white);
	}
}

string getTimeString()
{
	const f32 total_hours = getMap().getDayTime() * hours_count;
	const int hours = Maths::Floor(total_hours);
	const f32 fractional = total_hours - hours;
	const int minutes = Maths::Floor(fractional * 60.0f);
	const string min_str = (minutes < 10 ? "0" : "") + minutes;

	return (hours+1) + ":" + min_str;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	if (!this.getShape().isStatic()) return;

	Component@ component;
	if (!this.get("component", @component)) return;

	MapPowerGrid@ grid;
	if (!getRules().get("power grid", @grid)) return;

	bool[]@ hours_activated;
	if (!this.get("hours_activated", @hours_activated)) return;

	const u16 day_hour = Maths::Floor(getMap().getDayTime()*hours_count);
	if (day_hour >= hours_count) { error("Clock hours mismatch!"); return; }

	const bool isActivated = hours_activated[day_hour];

	const u8 old_info = grid.getInfo(component.x, component.y);
	const u8 info = !isActivated ? INFO_SOURCE : INFO_SOURCE | INFO_ACTIVE;

	if (old_info != info)
	{
		grid.setInfo(component.x, component.y, info);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!this.isOverlapping(caller) || !this.getShape().isStatic()) return;

	CButton@ button = caller.CreateGenericButton(11, Vec2f_zero, this, Callback_OpenMenu, Translate::SetHours);
	if (button !is null)
	{
		button.radius = 16.0f;
		button.enableRadius = 20.0f;
	}
}

void Callback_OpenMenu(CBlob@ this, CBlob@ caller)
{
	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), this, Vec2f(hours_count, 1), Translate::SetHours);
	if (menu is null) return;

	bool[]@ hours_activated;
	if (!this.get("hours_activated", @hours_activated)) return;

	for (u8 i = 0; i < hours_count; i++)
	{
		CBitStream stream;
		stream.write_netid(this.getNetworkID());
		stream.write_u8(i);
		CGridButton@ butt = menu.AddButton("ClockHours.png", i+1, Vec2f(20, 16), Translate::ToggleHour.replace("{INPUT}", (i+1)+""), "Clock.as", "Callback_SetHour", Vec2f(1, 1), stream);
		butt.SetSelected(hours_activated[i] ? 1 : 0);
	}
}

void Callback_SetHour(CBitStream@ params)
{
	u16 netid;
	if (!params.saferead_netid(netid)) return;

	u8 index;
	if (!params.saferead_u8(index)) return;

	CBlob@ this = getBlobByNetworkID(netid);
	if (this is null) return;

	ToggleHour(this, index);

	Callback_OpenMenu(this, null);

	if (!isServer())
	{
		CBitStream stream;
		stream.write_u8(index);
		this.SendCommand(this.getCommandID("server_sethour"), stream);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_sethour") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		u8 index;
		if (!params.saferead_u8(index)) { error("Failed to read clock hour index!"); return; }

		ToggleHour(this, index);

		CBitStream stream;
		Serialize(this, stream);
		this.SendCommand(this.getCommandID("client_sethour"), stream);
	}
	else if (cmd == this.getCommandID("client_sethour") && isClient())
	{
		Unserialize(this, params);
	}
}

void ToggleHour(CBlob@ this, const u8&in index)
{
	bool[]@ hours_activated;
	if (!this.get("hours_activated", @hours_activated)) return;

	if (index >= hours_activated.length) { error("Clock hour index out of bounds! ["+index+"]"); return; }

	hours_activated[index] = !hours_activated[index];
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void Serialize(CBlob@ this, CBitStream@ stream)
{
	bool[]@ hours_activated;
	if (!this.get("hours_activated", @hours_activated)) return;

	for (u8 i = 0; i < hours_count; i++)
	{
		stream.write_bool(hours_activated[i]);
	}
}

bool Unserialize(CBlob@ this, CBitStream@ stream)
{
	bool[] hours_activated(hours_count);

	for (u8 i = 0; i < hours_count; i++)
	{
		if (!stream.saferead_bool(hours_activated[i])) { error("Failed to unserialize clock hours!"); return false; }
	}

	this.set("hours_activated", hours_activated);

	return true;
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	Serialize(this, stream);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	return Unserialize(this, stream);
}
