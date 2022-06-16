const string delay_property = "brain_delay";
const string target_searchrad_property = "brain_target_rad";
const string destination_property = "brain_destination";
const string obstruction_threshold = "brain_obstruction_threshold";

shared class UndeadMoveVars
{
	//walking vars
	f32 walkSpeed;  //target vel
	f32 walkFactor;
	Vec2f walkLadderSpeed;

	//climbing vars
	bool climbingEnabled;

	//jumping vars
	f32 jumpMaxVel;
	f32 jumpStart;
	f32 jumpMid;
	f32 jumpEnd;
	f32 jumpFactor;
	s32 jumpCount; //internal counter

	//force applied while... stopping
	f32 stoppingForce;
	f32 stoppingForceAir;
	f32 stoppingFactor;

	//flying vars
	f32 flySpeed;
	f32 flyFactor;
};

shared const bool isTargetVisible(CBlob@ this, CBlob@ target)
{
	Vec2f col;
	
	if (getMap().rayCastSolid(this.getPosition(), target.getPosition(), col))
	{
		// fix for doors not being considered visible
		CBlob@ obstruction = getMap().getBlobAtPosition(col);
		if (obstruction is null || obstruction !is target)
			return false;
	}
	return true;
}

shared const f32 getDistanceBetween(Vec2f&in point1, Vec2f&in point2)
{
	return (point1 - point2).Length();
}
