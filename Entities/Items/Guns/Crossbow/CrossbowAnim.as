#include "CrossbowCommon.as"
#include "FireParticle.as";

void onInit(CSprite@ this)
{
	CSpriteLayer@ arrow = this.addSpriteLayer("held arrow", "Arrow.png", 16, 8, this.getBlob().getTeamNum(), 0);
	if (arrow !is null)
	{
		Animation@ anim = arrow.addAnimation("default", 0, false);
		anim.AddFrame(1); //normal
		anim.AddFrame(9); //water
		anim.AddFrame(8); //fire
		anim.AddFrame(14); //bomb
		anim.AddFrame(16); //molotov
		arrow.SetRelativeZ(-0.1f);
		arrow.SetOffset(Vec2f(-6, 0.5f));
		arrow.SetAnimation("default");
		arrow.SetVisible(false);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isAttached()) return;

	AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	CrossbowInfo@ crossbow;
	if (!blob.get("crossbowInfo", @crossbow)) return;

	DrawBow(this, blob, holder, crossbow);
}

void DrawBow(CSprite@ this, CBlob@ blob, CBlob@ holder, CrossbowInfo@ crossbow)
{
	CSpriteLayer@ arrow = this.getSpriteLayer("held arrow");

	if (!crossbow.loaded || crossbow.charge_state == Crossbow::none)
	{
		this.animation.frame = crossbow.charge_state == Crossbow::charged ? 2 : (crossbow.charge_time > Crossbow::READY_TIME/2 ? 1 : 0);
		arrow.SetVisible(false);
	}
	else if (crossbow.charge_state == Crossbow::charged) //charged
	{
		this.animation.frame = 2;

		arrow.SetVisible(true);
		arrow.animation.frame = crossbow.arrow_type;
	}
	else if (crossbow.charge_time > 0) //charging
	{
		this.animation.frame = crossbow.charge_time > Crossbow::READY_TIME/2 ? 1 : 0;
	}

	// fire arrow particles

	if (getGameTime() % 6 == 0 && crossbow.arrow_type == ArrowType::fire && crossbow.loaded && crossbow.charge_state == Crossbow::charged)
	{
		Vec2f offset = Vec2f(12.0f, 0.0f);
		offset *= this.isFacingLeft() ? -1 : 1;

		offset.RotateBy(blob.getAngleDegrees());
		makeFireParticle(this.getWorldTranslation() + offset, 4);
	}
	
	// set fire light
	if (crossbow.arrow_type == ArrowType::fire)
	{
		if (crossbow.charge_state == Crossbow::charged && crossbow.loaded)
		{
			blob.SetLight(true);
			blob.SetLightRadius(blob.getRadius() * 2.0f);
		}
		else
		{
			blob.SetLight(false);
		}
	}
}
