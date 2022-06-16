/* Targeting */

shared CBlob@ GetClosestVisibleTarget(CBrain@ this, CBlob@ blob, const f32&in radius)
{
	Vec2f pos = blob.getPosition();
	CBlob@[] nearBlobs;
	blob.getMap().getBlobsInRadius(pos, radius, @nearBlobs);

	CBlob@ best_candidate;
	f32 closest_dist = 999999.9f;
	
	const u16 blobsLength = nearBlobs.length;
	for (u16 i = 0; i < blobsLength; ++i)
	{
		CBlob@ candidate = nearBlobs[i];
		if (candidate is null || !canTarget(candidate) || candidate is blob) continue;
		
		const f32 dist = getDistanceBetween(candidate.getPosition(), pos);
		if (dist < closest_dist && isTargetVisible(blob, candidate))
		{
			@best_candidate = candidate;
			closest_dist = dist;
		}
	}
	return best_candidate;
}

shared CBlob@ GetBestTarget(CBrain@ this, CBlob@ blob, const f32&in radius)
{
	const bool seeThroughWalls = blob.hasTag("see_through_walls");
	const Vec2f pos = blob.getPosition();
	
	CBlob@[] nearBlobs;
	getMap().getBlobsInRadius(pos, radius, @nearBlobs);

	CBlob@ best_candidate;
	f32 closest_dist = 999999.9f;
	
	for (u16 i = 0; i < nearBlobs.length; ++i)
	{
		CBlob@ candidate = nearBlobs[i];
		if (candidate is null || !canTarget(candidate) || candidate is blob) continue;
		
		const bool is_visible = isTargetVisible(blob, candidate);

		const f32 dist = getDistanceBetween(candidate.getPosition(), pos);
		if (dist < closest_dist && (is_visible || seeThroughWalls))
		{
			if (!is_visible && XORRandom(30) > 3) continue;

			@best_candidate = candidate;
			closest_dist = dist;
		}
	}
	return best_candidate;
}

shared const bool canTarget(CBlob@ target)
{
	return !target.hasTag("dead") && !target.hasTag("undead") && //can't be dead (literally)
		   (target.hasTag("building") || target.hasTag("player") || target.hasTag("vehicle"));
}
