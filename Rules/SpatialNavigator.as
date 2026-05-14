// Zombie Fortress spatial navigation
// Gingerbeard @ May 14th, 2026

/*
 Spatial Navigation tool
   This script is a generic tool that can be used for things like:
   - Finding spawning locations for blobs
   - Finding areas for your blob to move to
   
   Should be noted: this tool is only configured for blobs with 2x2 tilesize
*/

funcdef f32 CostHandle(Vec2f, Navigator@);
funcdef bool ValidHandle(Vec2f, Navigator@);

class Navigator
{
	Vec2f origin;
	int width;
	int height;

	int space_above;

	CostHandle@[] cost_evaluators;
	ValidHandle@[] valid_evaluators;

	Navigator(Vec2f origin, const int&in width, const int&in height)
	{
		this.origin = getMap().getAlignedWorldPos(origin + Vec2f(4, 4));
		this.width = width;
		this.height = height;
		
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

	Vec2f getWeightedPosition()
	{
		Vec2f start_pos = origin - Vec2f(width * 4, height * 4);

		f32 best_cost = 999999.0f;
		Vec2f best_pos = origin;

		Vec2f[] candidates;

		for (int w = 0; w < width; w++)
		{
			for (int h = 0; h < height; h++)
			{
				Vec2f candidate = start_pos + Vec2f(w * 8, h * 8);
				if (!isValid(candidate)) continue;

				candidates.push_back(candidate);
			}
		}

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
	if (pos.x <= 0 || pos.x >= dim.x || pos.y >= dim.y) return false;
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


/// COSTS FUNCS
///  Determines how likely the position is- More cost equals less likely

f32 getRandomCost(Vec2f pos, Navigator@ vars)
{
	return XORRandom(50);
}

f32 getDistanceCost(Vec2f pos, Navigator@ vars)
{
	const f32 distance = (pos - vars.origin).Length();
	if (distance < 64.0f) return Maths::Abs(distance - 64.0f * 3);

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
