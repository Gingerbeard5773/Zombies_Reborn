// Wizard Phase

const f32 phase_speed = 10.0f;

void onTick(CBlob@ this)
{
	Vec2f destination = this.get_Vec2f("brain_destination");
	if (destination == Vec2f_zero) return;

	CShape@ shape = this.getShape();
	if (shape.isStatic())
	{
		Vec2f pos = this.getPosition();
		Vec2f direction = destination - pos;
		const f32 distance = direction.Length();
		direction.Normalize();

		if (distance <= phase_speed)
		{
			this.setPosition(destination);
			shape.SetStatic(false);
		}
		else
		{
			this.setPosition(pos + direction * phase_speed);
		}
	}
	else
	{
		this.setPosition(destination);
		this.setVelocity(Vec2f_zero);
	}

	if (this.hasTag("dead"))
	{
		shape.SetStatic(false);
		this.getCurrentScript().tickFrequency = 0;
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	this.set_bool("after_images", isStatic);

	if (!isStatic)
	{
		// engine bug fix
		this.SetFacingLeft(!this.isFacingLeft());
	}
}
