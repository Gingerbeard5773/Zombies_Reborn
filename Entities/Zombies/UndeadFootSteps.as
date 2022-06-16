// footstep sounds

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_onground;
	this.getCurrentScript().runFlags |= Script::tick_not_inwater;
	this.getCurrentScript().runFlags |= Script::tick_moving;
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;
	
    if (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right))
    {
		if ((blob.getNetworkID() + getGameTime()) % 9 == 0)
		{
			CMap@ map = getMap();
			const f32 volume = Maths::Min(0.1f + Maths::Abs(blob.getVelocity().x) * 0.1f, 1.0f);
			TileType tile = map.getTile(blob.getPosition() + Vec2f(0.0f, blob.getRadius() + 4.0f)).type;

			if (map.isTileGroundStuff(tile))
				this.PlaySound("/EarthStep", volume);
			else
				this.PlaySound("/StoneStep", volume);
		}
    }
}