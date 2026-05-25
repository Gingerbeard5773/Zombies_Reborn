const int fire_frequency = 25;
const f32 orb_speed = 4.0f;

void onInit(CBlob@ this)
{
	this.set_u32("magic_fire_charge", 0);
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	this.getCurrentScript().tickFrequency = 29;

	if (!this.isKeyPressed(key_action1))
	{
		this.set_u32("magic_fire_charge", 0);
		return;
	}

	this.getCurrentScript().tickFrequency = 1;

	u32 charge = this.get_u32("magic_fire_charge");
	charge++;

	if (charge >= fire_frequency)
	{
		Vec2f pos = this.getPosition();
		Vec2f aim = this.getAimPos();

		CBlob@ orb = server_CreateBlob("orb", this.getTeamNum(), pos);
		if (orb !is null)
		{
			Vec2f norm = aim - pos;
			norm.Normalize();
			Vec2f vel = norm * orb_speed;
			orb.setVelocity(vel);
		}

		charge = 0;
	}
	this.set_u32("magic_fire_charge", charge);
}
