// scroll script that speeds up time temporarily

#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_GlobalMessagesCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
	this.addCommandID("client_finish_spell");

	this.set_u32("current_increment", 0);

	this.getCurrentScript().tickIfTag = "used";

	this.SetLightRadius(75.0f);
	this.SetLightColor(SColor(255, 150, 240, 171));
	this.SetLight(false);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("SpellLoop.ogg");
	sprite.SetEmitSoundPaused(true);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	if (this.hasTag("used") || getRules().daycycle_speed == 1) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), desc(Translate("ScrollTime")));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (this.hasTag("used") || getRules().daycycle_speed == 1) return;

		Statistics::server_Add("scrolls_used", 1, player);
		this.Tag("used");

		this.server_DetachAll();
		this.getShape().SetStatic(true);

		this.SendCommand(this.getCommandID("client_execute_spell"));
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		this.Tag("used");
		Sound::Play("SpellMagic4.ogg");

		client_SendGlobalMessage(getRules(), Translate("ScrollTimeStart"), 5);
	}
}

void onTick(CBlob@ this)
{
	HandleEffects(this);

	Hover(this);

	getRules().daycycle_speed = 1;

	if (isServer() && getGameTime() % 30 == 0)
	{
		u32 time_passed = this.get_u32("current_increment");
		time_passed++;

		if (time_passed >= 60)
		{
			this.server_Die();
		}

		this.set_u32("current_increment", time_passed);
	}
}

void Hover(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	Vec2f up = pos + Vec2f(0, -8 * 5);
	Vec2f down = pos + Vec2f(0, 8 * 5);
	map.rayCastSolid(pos, up, up);
	map.rayCastSolid(pos, down, down);

	Vec2f middle_of_room = (up + down) * 0.5f;
	this.setPosition(Vec2f_lerp(pos, middle_of_room, 0.1f));
}

void HandleEffects(CBlob@ this)
{
	this.SetLight(true);

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(false);

	const f32 hover = Maths::Sin(getGameTime() * 0.05f) * 4.0f;
	sprite.SetOffset(Vec2f(0, hover));

	for (int i = 0; i < 4; i++)
	{
		CSpriteLayer@ layer = getCoinLayer(sprite, i);
		if (layer is null) continue;

		const f32 time = getGameTime() * 2.0f;
		const f32 angle = time + (i * 90.0f);

		Vec2f offset(12, 0);
		offset.RotateBy(angle);
		offset.y += hover;
		layer.SetOffset(offset);

		layer.ResetTransform();
		layer.RotateBy(90, Vec2f_zero);

		layer.SetVisible(true);
		layer.SetFacingLeft(false);
	}
}

CSpriteLayer@ getCoinLayer(CSprite@ sprite, const int&in index)
{
	const string layer_name = "magic_coin_"+index;
	CSpriteLayer@ layer = sprite.getSpriteLayer(layer_name);
	if (layer is null)
	{
		@layer = sprite.addSpriteLayer(layer_name, "coins.png", 16, 16, 5, 0);
		Animation@ spin = layer.addAnimation("spin", 2, true);
		int[] frames = { 3, 9, 15 };
		spin.AddFrames(frames);
		layer.SetAnimation(spin);
	}

	return layer;
}

u16 getOriginalDaycycleSpeed()
{
	ConfigFile cfg = ConfigFile();
	if (cfg.loadFile("Zombie Fortress/Gamemode.cfg"))
	{
		u16 daycycle_speed = cfg.read_u16("daycycle_speed", 8);
		return daycycle_speed;
	}
	return 8;
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("used")) return;

	getRules().daycycle_speed = getOriginalDaycycleSpeed();

	Vec2f pos = this.getPosition();
	Sound::Play("SpellMagic6.ogg", pos);
	ParticleAnimated("MediumSteam", pos, Vec2f_zero, f32(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
	ParticlesFromSprite(this.getSprite(), pos, Vec2f(0.0f, -0.5f), 50, 1);

	client_SendGlobalMessage(getRules(), Translate("ScrollTimeFinish"), 5);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("used");
}
