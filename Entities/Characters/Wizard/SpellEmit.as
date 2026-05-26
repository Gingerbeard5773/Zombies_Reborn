// Spell emit
// Used so that spell casters can have an emit sound for their spell while charging

void onInit(CBlob@ this)
{
	this.Tag("temp blob"); // dont get saved to the map saver

	this.SetVisible(false);

	CShape@ shape = this.getShape();
	shape.server_SetActive(false);
	shape.doTickScripts = false;
	this.doTickScripts = false;

	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;

	consts.net_threshold_multiplier = -1; // dont sync anything to clients
}
