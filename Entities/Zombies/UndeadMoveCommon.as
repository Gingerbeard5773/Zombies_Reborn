shared class UndeadMoveVars
{
	s32 jumpCount; //internal counter
	
	UndeadMoveConsts@ consts;
	
	UndeadMoveVars(UndeadMoveConsts@ consts_)
	{
		@consts = consts_;
	}
};

shared class UndeadMoveConsts
{
	//walking
	f32 walkSpeed;
	f32 walkFactor;

	//climbing
	u8 climbingFactor;

	//jumping
	f32 jumpMaxVel;
	f32 jumpFactor;

	//force applied while... stopping
	f32 stoppingForce;
	f32 stoppingForceAir;
	f32 stoppingFactor;

	//flying
	f32 flySpeed;
	f32 flyFactor;
};
