namespace Crossbow
{
	enum State
	{
		none = 0,
		charging,
		charged
	}
	
	const f32 SHOOT_VEL = 20.0f;
	const int READY_TIME = 35;
}

const string[] arrowTypeNames = { "mat_arrows", "mat_waterarrows", "mat_firearrows", "mat_bombarrows", "mat_molotovarrows" };

namespace ArrowType
{
	enum type
	{
		normal = 0,
		water,
		fire,
		bomb,
		molotov,
		count,
	};
}

shared class CrossbowInfo
{
	s8 charge_time;
	u8 charge_state;
	u8 arrow_type;
	bool loaded;

	CrossbowInfo()
	{
		charge_time = 0;
		charge_state = Crossbow::none;
		arrow_type = ArrowType::normal;
		loaded = false;
	}
};

f32 getAimAngle(CBlob@ this, CBlob@ holder)
{
	Vec2f aim_vec = (this.getPosition() - holder.getAimPos());
	aim_vec.Normalize();
	const f32 angle = aim_vec.getAngleDegrees() + (!this.isFacingLeft() ? 180 : 0);
	return -angle;
}
