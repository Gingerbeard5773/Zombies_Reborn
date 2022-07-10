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
	u8 climbingFactor;

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
