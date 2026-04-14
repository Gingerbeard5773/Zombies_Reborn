// Tim brain

#define SERVER_ONLY

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	const u8 strategy = blob.get_u8("strategy");

	if (!blob.getShape().isStatic())
	{
		if (blob.isInWater())
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}
