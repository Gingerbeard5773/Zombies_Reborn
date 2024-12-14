//common targeting

shared void SetBestTarget(CBrain@ this, CBlob@ blob, const f32&in radius)
{
	u16[]@ targetBlobs;
	if (!getRules().get("target netids", @targetBlobs)) return;
	
	const bool seeThroughWalls = blob.hasTag("see_through_walls");
	const Vec2f pos = blob.getPosition();

	CBlob@ target;
	f32 closest_dist = 999999.9f;
	
	const u16 blobsLength = targetBlobs.length;
	for (u16 i = 0; i < blobsLength; ++i)
	{
		CBlob@ candidate = getBlobByNetworkID(targetBlobs[i]);
		if (candidate is null || candidate.hasTag("dead")) continue;

		const f32 dist = (candidate.getPosition() - pos).Length();
		if (dist < radius && dist < closest_dist && (isTargetVisible(blob, candidate) || seeThroughWalls))
		{
			@target = candidate;
			closest_dist = dist;
		}
	}
	
	if (target !is null)
	{
		this.SetTarget(target);
	}
}

shared const bool isTargetVisible(CBlob@ this, CBlob@ target)
{
	return !getMap().rayCastSolid(this.getPosition(), target.getPosition());
}
