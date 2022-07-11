#include "UndeadMoveCommon.as";

const f32 turnaroundspeed = 1.3f;
const f32 normalspeed = 1.0f;
const f32 backwardsspeed = 0.8f;

void onInit(CMovement@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;
	
	UndeadMoveVars@ moveVars;
	if (!blob.get("moveVars", @moveVars)) return;
	
	CMap@ map = getMap();
	CShape@ shape = blob.getShape();
	
	const bool left    = blob.isKeyPressed(key_left);
	const bool right   = blob.isKeyPressed(key_right);
	const bool up      = blob.isKeyPressed(key_up);
	const bool down    = blob.isKeyPressed(key_down);
	
	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();
	
	const bool onground = blob.isOnGround() || blob.isOnLadder();
	
	bool onladder = blob.isOnLadder();
	
	// check if we need to scale a wall
	if (XORRandom(moveVars.climbingFactor) == 0 && !blob.isOnLadder() && (up || left || right)) //key pressed
	{
		//check solid tiles
		const f32 ts = map.tilesize;
		const f32 y_ts = ts * 0.2f;
		const f32 x_ts = ts * 1.4f;
		
		bool surface_left = map.isTileSolid(pos + Vec2f(-x_ts, y_ts-map.tilesize)) || map.isTileSolid(pos + Vec2f(-x_ts, y_ts));
		//TODO: fix flags sync and hitting so we dont have to do this
		if (!surface_left)
		{
			surface_left = checkForSolidMapBlob(map, pos + Vec2f(-x_ts, y_ts-map.tilesize)) ||
						   checkForSolidMapBlob(map, pos + Vec2f(-x_ts, y_ts));
		}
		
		bool surface_right = map.isTileSolid(pos + Vec2f(x_ts, y_ts-map.tilesize)) || map.isTileSolid(pos + Vec2f(x_ts, y_ts));
		//TODO: fix flags sync and hitting so we dont have to do this
		if (!surface_right)
		{
			surface_right = checkForSolidMapBlob(map, pos + Vec2f(x_ts, y_ts-map.tilesize)) ||
							checkForSolidMapBlob(map, pos + Vec2f(x_ts, y_ts));
		}
		
		// set onladder to true for scaling
		if (left && surface_left || right && surface_right)
			onladder = true;
	}
	
	// ladder and scaling walls - overrides other movement completely
	if (onladder && !blob.isAttached() && !blob.isOnGround())
	{
		shape.SetGravityScale(0.0f);
		Vec2f ladderforce;
		
		if (up)    ladderforce.y -= 1.0f;
		if (down)  ladderforce.y += 1.2f;
		
		if (left)  ladderforce.x -= 1.0f;
		if (right) ladderforce.x += 1.0f;
		
		blob.AddForce(ladderforce * 100.0f);
		//damp vel
		vel *= 0.05f;
		blob.setVelocity(vel);
		
		moveVars.jumpCount = -1;
		
		CleanUp(this, blob, moveVars);
		return;
	}
	
	shape.SetGravityScale(1.0f);
	shape.getVars().onladder = false;
	
	// jumping
	if (moveVars.jumpFactor > 0.01f)
	{
		if (onground)
			moveVars.jumpCount = 0;
		else
			moveVars.jumpCount++;
		
		if (up && vel.y > -moveVars.jumpMaxVel)
		{
			moveVars.jumpStart = 0.7f;
			moveVars.jumpMid = 0.2f;
			moveVars.jumpEnd = 0.1f;
			
			Vec2f force = Vec2f(0, 0);
			
			// jump
			if (moveVars.jumpCount <= 0)
				force.y -= 1.5f;
			else if (moveVars.jumpCount < 3)
				force.y -= moveVars.jumpStart;
			else if (moveVars.jumpCount < 6)
				force.y -= moveVars.jumpMid;
			else if (moveVars.jumpCount < 8)
				force.y -= moveVars.jumpEnd;
			
			force *= moveVars.jumpFactor * 60.0f;
			
			blob.AddForce(force);
		}
	}
	
	// left and right movement
	
	bool stop = true;
	if (!onground)
	{
		stop = !blob.hasTag("dont stop til ground");
	}
	else
	{
		blob.Untag("dont stop til ground");
	}
	
	const bool facingleft = blob.isFacingLeft();
	Vec2f walkDirection;
	
	if (right)
	{
		if (vel.x < -0.1f)
			walkDirection.x += turnaroundspeed;
		else if (facingleft)
			walkDirection.x += backwardsspeed;
		else
			walkDirection.x += normalspeed;
	}
	
	if (left)
	{
		if (vel.x > 0.1f)
			walkDirection.x -= turnaroundspeed;
		else if (!facingleft)
			walkDirection.x -= backwardsspeed;
		else
			walkDirection.x -= normalspeed;
	}
	
	f32 force = 1.0f;
	f32 lim = 0.0f;
	if (left || right)
	{
		lim = moveVars.walkSpeed;
		lim *= moveVars.walkFactor * Maths::Abs(walkDirection.x);
	}
	
	Vec2f stop_force;
	
	const bool greater = vel.x > 0;
	const f32 absx = greater ? vel.x : -vel.x;
	
	if (absx > lim)
	{
		if (stop) //stopping
		{
			stop_force.x -= (absx - lim) * (greater ? 1 : -1);
			
			stop_force.x *= 30.0f * moveVars.stoppingFactor *
						(onground ? moveVars.stoppingForce : moveVars.stoppingForceAir);
			
			if (absx > 3.0f)
			{
				f32 extra = (absx-3.0f);
				f32 scale = (1.0f/((1+extra) * 2));
				stop_force.x *= scale;
			}
			
			blob.AddForce(stop_force);
		}
	}
	
	if (absx < lim || left && greater || right && !greater)
	{
		force *= moveVars.walkFactor * 30.0f;
		if (Maths::Abs(force) > 0.01f)
			blob.AddForce(walkDirection*force);
	}

	// clean up
	CleanUp(this, blob, moveVars);
}

//cleanup all vars here - reset clean slate for next frame
void CleanUp(CMovement@ this, CBlob@ blob, UndeadMoveVars@ moveVars)
{
	//reset all the vars here
	moveVars.jumpFactor = 1.0f;
	moveVars.walkFactor = 1.0f;
}

//TODO: fix flags sync and hitting so we dont need this
const bool checkForSolidMapBlob(CMap@ map, Vec2f&in pos)
{
	CBlob@ blob = map.getBlobAtPosition(pos);
	if (blob !is null && blob.isCollidable())
	{
		return blob.getShape().isStatic();
	}
	
	return false;
}
