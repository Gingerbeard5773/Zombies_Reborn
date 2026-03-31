#include "Hitters.as"
#include "WraithCommon.as"

const int COINS_ON_DEATH = 60;

const u32 TIME_TO_ENRAGE_SPECTRE = TIME_TO_ENRAGE * 5.0f;

void onInit(CBlob@ this)
{
	this.set_u16("coins on death", COINS_ON_DEATH);

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("WraithSpawn.ogg");
	sprite.SetEmitSound("SpectreDrone2.ogg");
	sprite.SetEmitSoundPaused(false);
	sprite.SetRelativeZ(1);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);
	
	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("see_through_walls");
	this.Tag("wraith");
	
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	// explosiveness
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 32.0f);
	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_u8("custom_hitter", 26); //keg
	this.set_string("custom_explosion_sound", "KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.7f);
	this.set_bool("map_damage_raycast", true);
	this.set_s32("auto_enrage_time", getGameTime() + TIME_TO_ENRAGE_SPECTRE + XORRandom(TIME_TO_ENRAGE_SPECTRE / 2));
	//

	this.SetLight(true);
	this.SetLightRadius(60.0f);
	this.SetLightColor(SColor(255, 138, 100, 100));

	this.addCommandID("enrage_client");
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		const s32 auto_explode_timer = this.get_s32("auto_enrage_time") - getGameTime();
		if (this.isKeyPressed(key_action1) || auto_explode_timer < 0)
		{
			server_SetEnraged(this, true, false, false);
		}
	}

	if (this.getShape().isStatic())
	{
		Vec2f pos = this.getPosition();

		if ((this.getNetworkID() + getGameTime()) % 5 == 0)
		{
			Vec2f dir = this.getAimPos() - pos;
			dir.Normalize();
			dir *= 1.001f;
			this.setPosition(dir + pos);
		}

		bool phasing = OverlappingSolid(this, pos);
		if (!phasing && this.get_u32("phase_begin_time") + 45 < getGameTime())
		{
			this.getShape().SetStatic(false);
		}

		this.RenderForHUD(styles[XORRandom(styles.length)]);
	}
	else
	{
		this.RenderForHUD(RenderStyle::light);
	}
}

RenderStyle::Style[] styles = { RenderStyle::light, RenderStyle::outline };

Vec2f[] spots = { Vec2f(0, 0), Vec2f(6, -6), Vec2f(-6, 6), Vec2f(6, 6), Vec2f(-6, -6)};
bool OverlappingSolid(CBlob@ blob, Vec2f pos)
{
	CMap@ map = getMap();
	for (u8 i = 0; i < 5; i++)
	{
		Tile tile = map.getTile(pos + spots[i]);
		if (map.isTileSolid(tile)) return true;
	}
	
	CBlob@[] blobs;
	if (map.getBlobsInBox(pos - spots[3], pos + spots[3], @blobs))
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			CShape@ shape = b.getShape();
			if (!shape.getConsts().collidable || !shape.isStatic() || !blob.doesCollideWithBlob(b)) continue;

			if (b.hasTag("door")) return true;
		}
	}

	return false;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	CSprite@ sprite = this.getSprite();
	if (isStatic)
	{
		this.set_u32("phase_begin_time", getGameTime());

		sprite.SetEmitSound("SpectrePhase");
		sprite.SetEmitSoundVolume(0.9f);
		sprite.SetEmitSoundPaused(false);
		sprite.SetRelativeZ(750);
	}
	else
	{
		sprite.SetEmitSound("SpectreDrone2");
		sprite.SetEmitSoundVolume(1.0f);
		sprite.SetEmitSoundPaused(false);
		sprite.SetRelativeZ(1);

		// engine bug fix
		this.SetFacingLeft(!this.isFacingLeft());
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("player") && blob.getShape().isStatic();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		this.getSprite().PlaySound("ZombieHit");
	}
	
	switch(customData)
	{
		case Hitters::spikes:
			damage *= 0.0f;
			break;
	}

	/*if (customData == Hitters::fire)
	{
		server_SetEnraged(this);
	}*/

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("enrage_client") && isClient())
	{
		bool enrage, stun;
		if (!params.saferead_bool(enrage)) return;
		if (!params.saferead_bool(stun)) return;

		this.set_bool("exploding", enrage);

		if (enrage)
		{
			this.getSprite().PlaySound("SpectreScreech", 4.0f, 0.7f);

			this.SetLight(true);
			this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
			this.SetLightColor(SColor(255, 211, 121, 224));
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("DarkWraithDie");
	
	if (!this.hasTag("exploding")) return;

	this.getSprite().PlaySound("DarkWraithExplode", 1.0f, 0.9f);
}
