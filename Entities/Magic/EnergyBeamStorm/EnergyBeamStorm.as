
const u8 beams_count = 5;

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;

	this.server_SetTimeToDie(8);

	u16[] netids(beams_count, 0);

	if (isServer())
	{
		for (int i = 0; i < beams_count; i++)
		{
			CBlob@ new_beam = server_CreateBlob("energybeam", this.getTeamNum(), this.getPosition());
			if (new_beam is null) continue;

			if (this.exists("owner_netid"))
			{
				new_beam.set_netid("owner_netid", this.get_netid("owner_netid"));
			}
			new_beam.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			new_beam.set_s8("laser_movement_sign", XORRandom(2) == 0 ? -1 : 1);
			new_beam.server_SetTimeToDie(this.getTimeToDie());
			netids[i] = new_beam.getNetworkID();
		}
	}

	this.set("beam_netids", netids);
}

void onTick(CBlob@ this)
{
	u16[]@ netids;
	if (!this.get("beam_netids", @netids)) return;

	const f32 angle = this.getAngleDegrees();
	Vec2f pos = this.getPosition();
	Vec2f direction = Vec2f(1, 0).RotateBy(-angle);
	Vec2f perp_direction = Vec2f(0, 1).RotateBy(-angle);
	
	Random rand(this.getNetworkID() * 33 + getGameTime());

	for (int i = 0; i < netids.length; i++)
	{
		CBlob@ beam = getBlobByNetworkID(netids[i]);
		if (beam is null) continue;

		beam.setAngleDegrees(-angle);

		const s8 movement_sign = beam.get_s8("laser_movement_sign");
		beam.setPosition(beam.getPosition() + perp_direction * movement_sign * 1.5f);
		
		if (rand.NextRanged(30) == 0)
		{
			beam.set_s8("laser_movement_sign", -movement_sign);
		}
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	u16[]@ netids;
	if (!this.get("beam_netids", @netids)) return;
	
	for (int i = 0; i < beams_count; i++)
	{
		stream.write_netid(netids[i]);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u16[]@ netids;
	if (!this.get("beam_netids", @netids)) return true;
	
	for (int i = 0; i < beams_count; i++)
	{
		if (!stream.saferead_netid(netids[i])) { error("Failed to read beam netid ["+i+"] [EnergyBeamStorm]"); return false; }
	}

	return true;
}
