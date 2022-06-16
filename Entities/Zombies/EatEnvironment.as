#include "Hitters.as";

void onInit(CBlob@ this)
{
	if (!this.exists("bite damage"))
		this.set_f32("bite damage", 1.0f);

	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
	if (!isServer() || this.hasTag("dead")) return;
	
	CBlob@[] overlapping;
	if (this.getOverlapping(@overlapping))
	{
		Vec2f pos = this.getPosition();
		const u16 overlappingLength = overlapping.length;
		for (u16 i = 0; i < overlappingLength; i++)
		{
			CBlob@ b = overlapping[i];
			if (b.getShape().isStatic() && facingVictim(this, b, pos))
			{
				const Vec2f hitvel = b.getPosition() - pos;
				this.server_Hit(b, b.getPosition(), hitvel, this.get_f32("bite damage"), Hitters::muscles, true);
			}
		}
	}
}

const bool facingVictim(CBlob@ this, CBlob@ blob, Vec2f&in pos)
{
	Vec2f point1 = blob.getPosition();
	const bool facing_blob = this.isFacingLeft() ? point1.x < pos.x : point1.x > pos.x;
	return facing_blob;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (isClient() && damage > 0.0f && customData == Hitters::muscles)
	{
		Sound::Play(this.get_string("attack sound"), this.getPosition());
		this.getSprite().SetAnimation("attack");
	}
}
