#define CLIENT_ONLY

f32 zoomTarget = 1.0f;
float timeToScroll = 0.0f;

string _targetPlayer;
bool waitForRelease = false;

CPlayer@ targetPlayer()
{
	return getPlayerByUsername(_targetPlayer);
}

void SetTargetPlayer(CPlayer@ p, CCamera@ camera = null)
{
	_targetPlayer = "";
	if (p is null)
	{
		if (camera !is null)
			camera.setTarget(null);
		
		return;
	}
	_targetPlayer = p.getUsername();
}

void Spectator(CRules@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = getControls();

	if (camera is null || controls is null)
		return;

	//Zoom in and out using mouse wheel
	if (timeToScroll <= 0)
	{
		if (controls.mouseScrollUp)
		{
			timeToScroll = 7;
			if (zoomTarget < 1.0f)
				zoomTarget = 1.0f;
			else
				zoomTarget = 2.0f;
		}
		else if (controls.mouseScrollDown)
		{
			timeToScroll = 7;
			if (zoomTarget > 1.0f)
				zoomTarget = 1.0f;
			else
				zoomTarget = 0.5f;
		}
	}
	else
	{
		timeToScroll -= getRenderApproximateCorrectionFactor();
	}

	Vec2f pos = camera.getPosition();

	if (Maths::Abs(camera.targetDistance - zoomTarget) > 0.001f)
	{
		camera.targetDistance = (camera.targetDistance * (3 - getRenderApproximateCorrectionFactor() + 1.0f) + (zoomTarget * getRenderApproximateCorrectionFactor())) / 4;
	}
	else
	{
		camera.targetDistance = zoomTarget;
	}

	const f32 camSpeed = getRenderApproximateCorrectionFactor() * 15.0f / zoomTarget;

	//Move the camera using the action movement keys
	if (controls.ActionKeyPressed(AK_MOVE_LEFT))
	{
		pos.x -= camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_RIGHT))
	{
		pos.x += camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_UP))
	{
		pos.y -= camSpeed;
		SetTargetPlayer(null, camera);
	}
	if (controls.ActionKeyPressed(AK_MOVE_DOWN))
	{
		pos.y += camSpeed;
		SetTargetPlayer(null, camera);
	}

    if (controls.isKeyJustReleased(KEY_LBUTTON))
    {
        waitForRelease = false;
    }

	//Click on players to track them or set camera to mousePos
	Vec2f mousePos = controls.getMouseWorldPos();
	if (controls.isKeyJustPressed(KEY_LBUTTON) && !waitForRelease)
	{
		CBlob@[] players;
		SetTargetPlayer(null, camera);
		getBlobsByTag("player", @players);
		for (uint i = 0; i < players.length; i++)
		{
			CBlob@ blob = players[i];
			Vec2f bpos = blob.getInterpolatedPosition();

			if (Maths::Pow(mousePos.x - bpos.x, 2) + Maths::Pow(mousePos.y - bpos.y, 2) <= Maths::Pow(blob.getRadius() * 2, 2) && camera.getTarget() !is blob)
			{
				//print("set player to track: " + (blob.getPlayer() is null ? "null" : blob.getPlayer().getUsername()));
				SetTargetPlayer(blob.getPlayer(), camera);
				camera.setTarget(blob);
				camera.setPosition(blob.getInterpolatedPosition());
				return;
			}
		}
	}

	CPlayer@ targetPly = targetPlayer();
	if (targetPly !is null)
	{
		CBlob@ targetBlob = targetPly.getBlob();
		if (camera.getTarget() !is targetBlob)
		{
			camera.setTarget(targetBlob);
		}
	}

	//Set specific zoom if we have a target
	if (camera.getTarget() !is null)
	{
		camera.mousecamstyle = 1;
		camera.mouseFactor = 0.5f;
		return;
	}

	//Don't go off the map boundaries
	CMap@ map = getMap();
	if (map !is null)
	{
		Vec2f dim = map.getMapDimensions();
		const f32 boundary = map.tilesize * 2 / zoomTarget;

		if (pos.x < boundary) pos.x = boundary;
		if (pos.y < boundary) pos.y = boundary;
		
		if (pos.x > dim.x - boundary) pos.x = dim.x - boundary;
		if (pos.y > dim.y - boundary) pos.y = dim.y - boundary;
	}

	camera.setPosition(pos);
}
