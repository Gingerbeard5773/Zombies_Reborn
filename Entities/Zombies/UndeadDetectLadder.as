// set ladder if we're on it, otherwise set false

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
}

void onTick(CBlob@ this)
{
	ShapeVars@ vars = this.getShape().getVars();
	vars.onladder = false;

	CBlob@[] overlapping;
	if (!this.getOverlapping(@overlapping)) return;

	for (uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ overlap = overlapping[i];
		if (overlap.isLadder())
		{
			vars.onladder = true;
			return;
		}
	}
}
