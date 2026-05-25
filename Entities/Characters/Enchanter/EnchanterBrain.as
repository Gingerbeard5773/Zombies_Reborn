// Enchanter brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "SpatialNavigator.as"

const u32 teleport_delay = 30 * 10;
const u8 maximum_teleports = 4; 

void onInit(CBrain@ this)
{
	InitBrain(this);

	CBlob@ blob = this.getBlob();
	blob.set_u32("teleport_time", 0);
	blob.set_u8("teleport_count", 0);

	this.server_SetActive(true); // always running
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	SetAttacker(this, blob);

	this.getCurrentScript().tickFrequency = 29;

	CBlob@ target = this.getTarget();
	if (target !is null)
	{
		this.getCurrentScript().tickFrequency = 1;

		if (blob.getDistanceTo(target) < 250.0f)
		{
			blob.setAimPos(target.getPosition());
			blob.setKeyPressed(key_action1, true);
		}

		AttemptTeleport(blob);
	}
	else if (blob.get_u32("enchanting_time") == 0)
	{
		RandomTurn(blob);
	}

	FloatInWater(blob); 
} 

void SetAttacker(CBrain@ this, CBlob@ blob, const f32&in radius = 250.0f)
{
	Vec2f pos = blob.getPosition();

	CBlob@[] blobsInRadius;
	getMap().getBlobsInRadius(pos, radius, @blobsInRadius);

	CBlob@ attacker = null;
	Vec2f closest_pos = Vec2f_zero;
	f32 closest_dist = radius;

	for (u16 i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if ((!b.hasTag("undead") && !b.hasTag("skelepede")) || b.isAttached()) continue;

		if (getMap().rayCastSolid(pos, b.getPosition())) continue;

		Vec2f b_pos = b.getPosition();
		const f32 dist = (pos - b_pos).Length();
		if (dist < closest_dist)
		{
			@attacker = b;
			closest_pos = b_pos;
			closest_dist = dist;
		}
	}

	this.SetTarget(attacker);
}

void AttemptTeleport(CBlob@ blob)
{
	if (getGameTime() % 60 != 0) return;

	if (getGameTime() < blob.get_u32("teleport_time") + teleport_delay) return;

	// too many zombies nearby
	if (getNearbyUndeadCost(blob.getPosition(), null) < 250.0f) return;

	const u32 teleport_count = blob.get_u8("teleport_count") + 1;
	blob.set_u8("teleport_count", teleport_count);
	blob.set_u32("teleport_time", getGameTime());

	Teleport(blob);

	// If tim has to teleport too much, he gets mad and just leaves
	if (teleport_count > maximum_teleports)
	{
		blob.set_u32("time till departure", getGameTime() + 270);
		blob.Sync("time till departure", true);
	}
}

void Teleport(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();

	Navigator navigator(pos);
	navigator.space_above = 2;
	navigator.cost_evaluators = { @getProximityCost, @getRandomCost, @getTouchingBlobsCost, @getWaterCost, @getNearbyUndeadCost };
	navigator.valid_evaluators = { @isInMap, @isOpenSpace, @hasOpenSpaceAbove, @isOnGround };
	Vec2f teleport_pos = navigator.getBestPositionFromOrigin(50, 50);

	if ((pos - teleport_pos).Length() < 100.0f) return;

	blob.setPosition(teleport_pos);

	CBitStream stream;
	stream.write_Vec2f(pos);
	stream.write_Vec2f(teleport_pos);
	blob.SendCommand(blob.getCommandID("client_teleport"), stream);
}
