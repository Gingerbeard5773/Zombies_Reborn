// scroll script that makes you go back in time

#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "SaveFileCommon.as"

const u8 TIME_TRAVEL_DAYS = 2; // also edit LoadSavedRules.as to fully change this

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
	
	this.getCurrentScript().tickIfTag = "used";
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	if (this.hasTag("used")) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), desc(Translate("ScrollRewind")));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (this.hasTag("used")) return;

		if (!canTimeTravel())
		{
			server_SendGlobalMessage(getRules(), Translate("ScrollRewindFail"), 3, color_white.color, player);
			return;
		}

		Statistics::server_Add("scrolls_used", 1, player);
		this.Tag("used");

		this.server_DetachFromAll();
		this.server_SetTimeToDie(3);

		SetBlobDeactivated(this);

		getRules().set_netid("time_travel_netid", this.getNetworkID());

		this.SendCommand(this.getCommandID("client_execute_spell"));
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		this.Tag("used");

		SetBlobDeactivated(this);

		Sound::Play("Invigorate.ogg");
		Sound::Play("Mana.ogg");

		ParticleFlash(this.getPosition());
		ParticleWhiteSparks(this.getPosition(), 75);

		client_SendGlobalMessage(getRules(), Translate("ScrollRewindStart"), 5, ConsoleColour::CRAZY.color);
	}
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	const f32 alpha = this.get_f32("screen_alpha");

	SetScreenFlash(alpha, 255, 255, 255, 10);

	this.set_f32("screen_alpha", Maths::Min(alpha + 2.75f, 255));
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("used")) return;

	if (!isServer()) return;

	CRules@ rules = getRules();
	const u16 day_number = rules.get_u16("day_number");
	const u16 num = (day_number - TIME_TRAVEL_DAYS) % (TIME_TRAVEL_DAYS + 1);

	print("Scroll of Rewind :: Loading TimeSave"+num, ConsoleColour::CRAZY);

	rules.set_string("mapsaver_save_slot", "TimeSave"+num);
	rules.set_bool("loaded_saved_map", false);
	LoadNextMap();
}

bool canTimeTravel()
{
	CRules@ rules = getRules();
	const u16 day_number = rules.get_u16("day_number");
	if (day_number < 3) return false;

	const u16 num = (day_number - TIME_TRAVEL_DAYS) % (TIME_TRAVEL_DAYS + 1);

	ConfigFile config = ConfigFile();
	if (!config.loadFile("../Cache/"+Save::SaveFileName+"TimeSave"+num)) return false;

	// Enough time must have passed
	const u16 dayNumber = config.read_u16("day_number", 0);
	if (day_number - TIME_TRAVEL_DAYS < dayNumber) return false;

	// Saved file must be on the same map
	const s32 mapSeed = config.read_s32("map_seed", 0);
	if (mapSeed != rules.get_s32("map_seed")) return false;

	return true;
}

void SetBlobDeactivated(CBlob@ this)
{
	this.SetVisible(false);
	this.SetLight(false);

	CShape@ shape = this.getShape();
	shape.server_SetActive(false);
	shape.doTickScripts = false;

	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;
}

void ParticleFlash(Vec2f pos)
{
	CParticle@ p = ParticleAnimated("Flash2.png", pos, Vec2f_zero, 0, 1.0f, 3, 0.0f, true);
	if (p !is null)
	{
		p.Z = 600.0f;
	}
}

Random sparks_random(45354);
void ParticleWhiteSparks(Vec2f pos, const int&in amount)
{
	for (int i = 0; i < amount; i++)
	{
		Vec2f vel(sparks_random.NextFloat() * 4.0f, 0);
		vel.RotateBy(sparks_random.NextFloat() * 360.0f);

		SColor col = SColor(255, 200 + sparks_random.NextRanged(55), 200 + sparks_random.NextRanged(55), 255);
		CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
		if (p is null) return;

		p.fastcollision = true;
		p.gravity = Vec2f(0.0f, 0.02f);
		p.timeout = 20 + sparks_random.NextRanged(20);
		p.damping = 0.95f;
	}
}
