void onInit(CBlob@ this)
{
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(-50.0f); //push to background
	getMap().AddMarker(this.getPosition() + Vec2f(0, 20), "zombie_spawn");
}
