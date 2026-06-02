// Zombie Fortress spatial navigation
// Gingerbeard @ May 14th, 2026

/*
 Spatial Navigation tool
   This script is a generic tool that can be used for things like:
   - Finding spawning locations for blobs
   - Finding areas for your blob to move to
*/

funcdef f32 CostHandle(Vec2f, Navigator@);
funcdef bool ValidHandle(Vec2f, Navigator@);

class Navigator
{
	Vec2f origin;

	int space_above = 0;
	f32 proximity = 64.0f;

	CostHandle@[] cost_evaluators;
	ValidHandle@[] valid_evaluators;

	Navigator() {}

	Navigator(Vec2f origin)
	{
		this.origin = getMap().getAlignedWorldPos(origin + Vec2f(4, 4));

		AddValidEvaluator(@isInMap);
	}

	void AddCostEvaluator(CostHandle@ handle)
	{
		cost_evaluators.push_back(handle);
	}

	void AddValidEvaluator(ValidHandle@ handle)
	{
		valid_evaluators.push_back(handle);
	}

	Vec2f getBestPositionFromOrigin(const int&in width, const int&in height)
	{
		Vec2f[]@ candidates = getValidPositionsInBox(origin, width, height);
		return getBestPosition(candidates);
	}
	
	Vec2f getBestPositionFromOrigin(const f32&in radius)
	{
		Vec2f[]@ candidates = getValidPositionsInRadius(origin, radius);
		return getBestPosition(candidates);
	}

	Vec2f[]@ getValidPositionsInBox(Vec2f center, const int&in width, const int&in height)
	{
		Vec2f half_size(width * 4, height * 4);
		Vec2f tl = center - half_size;
		Vec2f br = center + half_size;
		return getValidPositionsInBox(tl, br);
	}

	Vec2f[]@ getValidPositionsInBox(Vec2f tl, Vec2f br)
	{
		Vec2f[] candidates;

		if (tl.x > br.x) { f32 t = tl.x; tl.x = br.x; br.x = t; }
		if (tl.y > br.y) { f32 t = tl.y; tl.y = br.y; br.y = t; }

		CMap@ map = getMap();

		tl = map.getAlignedWorldPos(tl);
		br = map.getAlignedWorldPos(br);

		for (f32 x = tl.x; x <= br.x; x += 8.0f)
		{
			for (f32 y = tl.y; y <= br.y; y += 8.0f)
			{
				Vec2f candidate(x, y);

				if (!isValid(candidate)) continue;

				candidates.push_back(candidate);
			}
		}

		return candidates;
	}

	Vec2f[]@ getValidPositionsInRadius(Vec2f center, const f32&in radius)
	{
		Vec2f[] candidates;

		CMap@ map = getMap();

		center = map.getAlignedWorldPos(center);

		for (f32 x = -radius; x < radius; x += 8.0f)
		{
			for (f32 y = -radius; y < radius; y += 8.0f)
			{
				Vec2f off(x, y);
				if (off.LengthSquared() > radius * radius) continue;

				Vec2f candidate = center + off;

				if (!isValid(candidate)) continue;

				candidates.push_back(candidate);
			}
		}

		return candidates;
	}

	// Finds the candidate with the lowest cost from the passed list
	Vec2f getBestPosition(Vec2f[]@ candidates)
	{
		f32 best_cost = 999999.0f;
		Vec2f best_pos = origin;

		while (candidates.length > 0)
		{
			const int index = XORRandom(candidates.length);
			Vec2f candidate = candidates[index];

			const f32 cost = getCost(candidate);
			if (cost < best_cost)
			{
				best_cost = cost;
				best_pos = candidate;
			}

			//VisualizeCost(candidate, cost);

			candidates.erase(index);
		}

		return best_pos;
	}

	f32 getCost(Vec2f pos)
	{
		f32 cost = 0.0f;
		for (int i = 0; i < cost_evaluators.length; i++)
		{
			cost += cost_evaluators[i](pos, this);
		}
		return cost;
	}

	bool isValid(Vec2f pos)
	{
		for (int i = 0; i < valid_evaluators.length; i++)
		{
			if (!valid_evaluators[i](pos, this)) return false;
		}
		return true;
	}
}


/// VALID FUNCS
///  Determines if the position is even possible

Vec2f[] corners = { Vec2f(-4, -4), Vec2f(4, -4), Vec2f(-4, 4), Vec2f(4, 4) };

bool isInMap(Vec2f pos, Navigator@ vars)
{
	Vec2f dim = getMap().getMapDimensions();
	const f32 margin = 16.0f;
	if (pos.x <= margin || pos.x >= dim.x - margin || pos.y >= dim.y - margin) return false;
	return true;
}

bool isOpenSpace(Vec2f pos, Navigator@ vars)
{
	CMap@ map = getMap();
	for (int i = 0; i < 4; i++)
	{
		Tile tile = map.getTile(pos + corners[i]);
		if (map.isTileSolid(tile)) return false;
	}
	return true;
}

bool hasOpenSpaceAbove(Vec2f pos, Navigator@ vars)
{
	CMap@ map = getMap();
	Vec2f start_pos = pos - Vec2f(8, (vars.space_above + 1) * 8) + Vec2f(4, 4);

	for (int x = 0; x < 2; x++)
	{
		for (int y = 0; y < vars.space_above; y++)
		{
			Tile tile = map.getTile(start_pos + Vec2f(x * 8, y * 8));
			if (map.isTileSolid(tile)) return false;
		}
	}
	return true;
}

bool isOnGround(Vec2f pos, Navigator@ vars)
{
	CMap@ map = getMap();
	if (!map.isTileSolid(map.getTile(pos + Vec2f(4, 12))) &&
	    !map.isTileSolid(map.getTile(pos + Vec2f(-4, 12))))
	{
		return false;
	}
	return true;
}

bool isUnobstructedByBlobs(Vec2f pos, Navigator@ vars)
{
	CMap@ map = getMap();
	CBlob@[] blobs;
	Vec2f tl(pos.x - 2, pos.y - 2);
	Vec2f br(pos.x + 2, pos.y + 2);
	if (!map.getBlobsInBox(tl, br, @blobs)) return true;

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		CShape@ shape = blob.getShape();
		if (shape is null) continue;
		
		if (!blob.isCollidable() || blob.isPlatform()) continue;

		if (shape.isStatic() && shape.getConsts().support > 0)
		{
			return false;
		}
	}
	
	return true;
}


/// COSTS FUNCS
///  Determines how likely the position is- More cost equals less likely

f32 getRandomCost(Vec2f pos, Navigator@ vars)
{
	return XORRandom(50);
}

f32 getProximityCost(Vec2f pos, Navigator@ vars)
{
	const f32 distance = (pos - vars.origin).Length();
	if (distance < vars.proximity) return Maths::Abs(distance - vars.proximity * 2);

	return 0.0f;
}

f32 getVisibleCost(Vec2f pos, Navigator@ vars)
{
	if (getMap().rayCastSolid(pos, vars.origin)) return 200.0f;

	return 0.0f;
}

f32 getWaterCost(Vec2f pos, Navigator@ vars)
{
	CMap@ map = getMap();
	if (map.isInWater(pos + Vec2f(4, -4)) || 
	    map.isInWater(pos + Vec2f(-4, -4)))
	{
		return 200.0f;
	}
	return 0.0f;
}

f32 getTouchingBlobsCost(Vec2f pos, Navigator@ vars)
{
	f32 cost = 0.0f;
	CBlob@[] nearby;
	getMap().getBlobsInRadius(pos, 24.0f, @nearby);

	for (int i = 0; i < nearby.length; i++)
	{
		CBlob@ b = nearby[i];
		if (b.getName() == "grain_plant" || b.hasTag("tree"))
		{
			cost += 15.0f; continue;
		}

		if (b.hasTag("building"))
		{
			cost += 10.0f; continue;
		}

		if (b.getName() == "saw")
		{
			cost += 50.0f; continue;
		}
	}
	return cost;
}

f32 getNearbyUndeadCost(Vec2f pos, Navigator@ vars)
{
	f32 cost = 0.0f;
	CBlob@[] nearby;
	getMap().getBlobsInRadius(pos, 150.0f, @nearby);

	for (int i = 0; i < nearby.length; i++)
	{
		CBlob@ b = nearby[i];
		if (!b.hasTag("undead")) continue;

		const f32 distance = (pos - b.getPosition()).Length();
		const f32 distance_penalty = Maths::Max(150.0f - distance, 0.0f) * 0.25f;

		cost += distance_penalty + 25.0f;
	}
	return cost;
}


/// DEBUG

CParticle@ VisualizeCost(Vec2f pos, const f32&in cost)
{
	const f32 MAX_COST = 500.0f;

	f32 t = cost / MAX_COST;
	t = Maths::Clamp(t, 0.0f, 1.0f);

	u8 r = 0;
	u8 g = 0;
	u8 b = 0;

	if (t < 0.5f)
	{
		// green -> yellow
		f32 k = t / 0.5f;

		r = u8(255 * k);
		g = 255;
	}
	else
	{
		// yellow -> red
		f32 k = (t - 0.5f) / 0.5f;

		r = 255;
		g = u8(255 * (1.0f - k));
	}

	SColor color(255, r, g, b);

	CParticle@ p = ParticlePixelUnlimited(pos, Vec2f_zero, color, true);
	if (p !is null)
	{
		p.timeout = 30;
		p.gravity = Vec2f_zero;
		p.collides = false;
		p.Z = 1000.0f;
	}

	return p;
}
