// Gingerbeard @ January 13th, 2025
// A* Pathfinding Implementation for King Arthur's Gold

#include "PathingNodesCommon.as";
#include "RunnerCommon.as";

/*
 High-level pathing ensures efficient, large-scale navigation across the map.
 Low-level pathing provides precise, obstacle-aware movement.

 When applied in the system:
  - High-level pathing determines the general route.
  - Low-level pathing follows that route waypoint to waypoint.
*/
 
funcdef void onPathDestinationHandle(CBlob@, BrainPath@);

void addOnPathDestination(CBlob@ this, onPathDestinationHandle@ handle)     { this.set("onPathDestination handle", @handle); }

const u32 stuck_time = 30 * 3; // Time it takes to shut off a specific waypoint if the bot cannot pass fast enough

const f32 maximum_pathing_distance_high_level = tilesize * 70;
const f32 maximum_pathing_distance_low_level = tilesize * 15;

class BrainPath
{
	CMap@ map = getMap();

	CBlob@ blob;                 // Our blob
	Vec2f[] waypoints;           // High level path
	Vec2f[] path;                // Low level path
	dictionary cached_waypoints; // Stuck nodes for 'stuck' state processing
	u8 flags;                    // Decides what paths to use
	u8 variance;                 // Max amount of random cost we give to each high level node
	f32 reach_low_level;         // What distance we can 'reach' low level path nodes
	f32 reach_high_level;        // What distance we can 'reach' high level waypoints

	BrainPath(CBlob@ blob_, const u8&in flags = Path::GROUND)
	{
		@blob = blob_;
		this.flags = flags;

		reach_low_level = 10.0f;
		reach_high_level = 10.0f;
		variance = 50;
	}

	void Tick()
	{
		// Handle 'stuck' operations
		Vec2f position = blob.getPosition();
		const string[]@ cached_keys = cached_waypoints.getKeys();
		for (int i = 0; i < cached_keys.length; i++)
		{
			CachedWaypoint@ cached_waypoint;
			if (!cached_waypoints.get(cached_keys[i], @cached_waypoint)) continue;

			// Remove cached waypoints that we have reached
			if ((cached_waypoint.position - position).Length() < reach_high_level)
			{
				cached_waypoints.delete(cached_keys[i]);
				continue;
			}

			if (cached_waypoint.stuck) continue;

			// Determine if the waypoint is a 'stuck' waypoint
			if (waypoints.length > 0 && waypoints[0] == cached_waypoint.position)
			{
				cached_waypoint.time++;

				if (cached_waypoint.time > stuck_time)
				{
					// Set a new path that re-routes around the stuck waypoint
					cached_waypoint.stuck = true;
					SetPath(position, waypoints[waypoints.length - 1]);
				}
			}
		}

		while (path.length > 0 && (path[0] - position).Length() < reach_low_level)
		{
			// Remove paths that we have reached
			path.removeAt(0);
		}

		while (waypoints.length > 0 && (waypoints[0] - position).Length() < reach_high_level)
		{
			ProgressPath();
		}
	}

	void ProgressPath()
	{
		// Remove waypoints that we have reached
		const string waypoint_key = waypoints[0].toString();
		if (cached_waypoints.exists(waypoint_key))
		{
			cached_waypoints.delete(waypoint_key);
		}

		waypoints.removeAt(0);
		path.clear();
		if (waypoints.length > 0)
		{
			SetLowLevelPath(blob.getPosition(), waypoints[0]);
			CacheWaypoint(waypoints[0]);
		}
		else
		{
			EndPath();

			onPathDestinationHandle@ onPathDestination;
			if (blob.get("onPathDestination handle", @onPathDestination))
			{
				onPathDestination(blob, this);
			}
		}
	}

	void CacheWaypoint(Vec2f&in waypoint)
	{
		// Cache the waypoint as a potential 'stuck' node
		const string waypoint_key = waypoint.toString();
		if (!cached_waypoints.exists(waypoint_key))
		{
			CachedWaypoint@ cached = CachedWaypoint(waypoint);
			cached_waypoints.set(waypoint_key, cached);
		}
	}

	void SetPath(Vec2f&in start, Vec2f&in target)
	{
		SetHighLevelPath(start, target);
		if (waypoints.length > 0)
		{
			CacheWaypoint(waypoints[0]);
			SetLowLevelPath(start, waypoints[0]);
		}
	}

	void EndPath()
	{
		waypoints.clear();
		path.clear();
		cached_waypoints.deleteAll();
		StopMovement();
	}
	
	void StopMovement()
	{
		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);
		blob.setKeyPressed(key_up, false);
		blob.setKeyPressed(key_down, false);
	}

	Vec2f alignToPathGrid(Vec2f&in pos)
	{
		return map.getAlignedWorldPos(pos + Vec2f(halfsize, halfsize));
	}

	bool isPathing()
	{
		return waypoints.length > 0 || path.length > 0;
	}

	/// Heuristics

	f32 euclidean(Vec2f&in a, Vec2f&in b)
	{
		return (a - b).Length(); // Euclidean distance
	}

	f32 manhattan(Vec2f&in a, Vec2f&in b)
	{
		return Maths::Abs(a.x - b.x) + Maths::Abs(a.y - b.y); // Manhattan distance
	}

	/// High level

	void SetHighLevelPath(Vec2f&in start, Vec2f&in target)
	{
		waypoints.clear();

		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return;

		HighLevelNode@ startNode = HighLevelNode(alignToPathGrid(start), flags);
		HighLevelNode@ targetNode = HighLevelNode(alignToPathGrid(target), flags);

		// Connect our temporary start & target nodes to the node map web
		SetTempNodeToMap(startNode, nodeMap);
		SetTempNodeToMap(targetNode, nodeMap);

		HighLevelNode@[] openList;
		dictionary closedList;

		startNode.gCost = 0.0f;
		startNode.hCost = euclidean(startNode.position, targetNode.position);
		@startNode.parent = null;

		openList.push_back(startNode);

		HighLevelNode@ closestNode = null;
		f32 closestDistance = 999999.0f;

		while (openList.length > 0)
		{
			// Find the node with the lowest fCost in the open list
			int currentIndex = 0;
			for (int i = 1; i < openList.length; i++)
			{
				HighLevelNode@ a = openList[i];
				HighLevelNode@ b = openList[currentIndex];
				if (a.fCost() < b.fCost() || (a.fCost() == b.fCost() && a.hCost < b.hCost))
				{
					currentIndex = i;
				}
			}

			HighLevelNode@ currentNode = openList[currentIndex];

			// Skip if the node is blacklisted
			CachedWaypoint@ cached_waypoint;
			if (cached_waypoints.get(currentNode.position.toString(), @cached_waypoint))
			{
				if (cached_waypoint.stuck)
				{
					openList.removeAt(currentIndex);
					continue;
				}
			}

			// Check if the target node is reached
			if (currentNode.position == targetNode.position)
			{
				@closestNode = currentNode;
				break;
			}

			// Otherwise, use the closest node available
			const f32 distanceToTarget = euclidean(currentNode.position, targetNode.position);
			if (distanceToTarget < closestDistance)
			{
				closestDistance = distanceToTarget;
				@closestNode = currentNode;
			}

			// Remove the current node from the open list and add it to the closed list
			openList.removeAt(currentIndex);
			closedList.set(currentNode.original_position.toString(), true);

			// Evaluate all neighbors of the current node
			for (uint i = 0; i < currentNode.connections.length; i++)
			{
				HighLevelNode@ neighbor = currentNode.connections[i];
				if (closedList.exists(neighbor.original_position.toString())) continue;
				
				if (!neighbor.hasFlag(flags)) continue;

				if ((neighbor.position - startNode.position).Length() > maximum_pathing_distance_high_level) continue;

				const f32 waterCost = isUnderwater(currentNode.position) ? 60 : 0;
				const f32 groundCost = isGrounded(neighbor.position) ? 0 : 40;
				const f32 randomCost = XORRandom(variance);
				const f32 tentativeGCost = currentNode.gCost + waterCost + groundCost + randomCost + euclidean(currentNode.position, neighbor.position);

				// Check if the neighbor is not in the open list or if a better path is found
				const bool isEvaluated = isInOpenList(neighbor, openList);
				if (tentativeGCost < neighbor.gCost || !isEvaluated)
				{
					// Update the neighbor's costs and set its parent
					neighbor.gCost = tentativeGCost;
					neighbor.hCost = euclidean(neighbor.position, targetNode.position);
					@neighbor.parent = currentNode;

					if (!isEvaluated)
					{
						openList.push_back(neighbor);
					}
				}
			}
		}

		// Reconstruct the best path to the target
		while (closestNode !is null)
		{
			waypoints.insertAt(0, closestNode.position);
			@closestNode = closestNode.parent;
		}

		// Remove any connections with our temporary nodes
		RemoveTempNodeFromMap(startNode);
		RemoveTempNodeFromMap(targetNode);
	}

	bool isInOpenList(HighLevelNode@ node, HighLevelNode@[]&in openList)
	{
		for (int i = 0; i < openList.length; i++)
		{
			if (openList[i] is node) return true;
		}
		return false;
	}

	// Connects nearby nodes from the nodemap to our node
	void SetTempNodeToMap(HighLevelNode@ node, HighLevelNode@[]@ nodeMap)
	{
		HighLevelNode@[] nodes = getNodesInRadius(node.position, node_distance * 1.7f, nodeMap, node.flags);
		for (u32 i = 0; i < nodes.length; i++)
		{
			HighLevelNode@ neighbor = nodes[i];
			if (!canNodesConnect(node, neighbor, map)) continue;

			node.connections.push_back(@neighbor);
			neighbor.connections.push_back(@node);
		}
	}

	// Removes connections to our temporary node
	void RemoveTempNodeFromMap(HighLevelNode@ node)
	{
		for (u32 i = 0; i < node.connections.length; i++)
		{
			HighLevelNode@ neighbor = node.connections[i];
			for (int c = neighbor.connections.length - 1; c >= 0; c--)
			{
				if (neighbor.connections[c] is node) neighbor.connections.erase(c);
			}
		}
	}

	// Determines if a path's target can be reached
	// Can sometimes fail on particularly complex paths due to optimizations
	bool canPath(Vec2f&in start, Vec2f&in target)
	{
		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return false;

		HighLevelNode@ startNode = HighLevelNode(alignToPathGrid(start), flags);
		HighLevelNode@ targetNode = HighLevelNode(alignToPathGrid(target), flags);

		// Connect our temporary start & target nodes to the node map web
		SetTempNodeToMap(startNode, nodeMap);
		SetTempNodeToMap(targetNode, nodeMap);

		f32 progressThreshold = euclidean(startNode.position, targetNode.position);
		Vec2f closestPos = startNode.position;

		bool canPath = false, outOfBounds = false;

		dictionary closedList;
		HighLevelNode@[] openList;
		openList.push_back(startNode);

		while (openList.length > 0)
		{
			int bestIndex = 0;
			f32 bestDistance = euclidean(openList[0].position, targetNode.position);

			for (uint i = 1; i < openList.length(); i++)
			{
				const f32 dist = euclidean(openList[i].position, targetNode.position);
				if (dist < bestDistance)
				{
					bestDistance = dist;
					bestIndex = i;
				}
			}

			HighLevelNode@ currentNode = openList[bestIndex];
			if (currentNode.position == targetNode.position)
			{
				canPath = true;
				break;
			}

			openList.removeAt(bestIndex);
			closedList.set(currentNode.original_position.toString(), true);

			if (bestDistance < progressThreshold)
			{
				progressThreshold = bestDistance;
				closestPos = currentNode.position;
			}

			for (uint i = 0; i < currentNode.connections.length; i++)
			{
				HighLevelNode@ neighbor = currentNode.connections[i];
				if (closedList.exists(neighbor.original_position.toString())) continue;

				if (!neighbor.hasFlag(flags)) continue;

				if ((neighbor.position - closestPos).Length() > maximum_pathing_distance_high_level * 0.5f)
				{
					outOfBounds = true;
					break;
				}

				if (!isInOpenList(neighbor, openList))
				{
					openList.insertAt(0, neighbor);
				}
			}

			if (outOfBounds) break;

			openList.set_length(Maths::Min(openList.length, 8)); // Optimization
		}

		// Remove any connections with our temporary nodes
		RemoveTempNodeFromMap(startNode);
		RemoveTempNodeFromMap(targetNode);

		return canPath;
	}


	/// Low level

	void SetLowLevelPath(Vec2f&in start, Vec2f&in target)
	{
		start = alignToPathGrid(start);
		target = alignToPathGrid(target);

		path.clear();

		LowLevelNode@[] openList;
		dictionary closedList;

		openList.push_back(LowLevelNode(start, 0, manhattan(start, target), null));

		while (openList.length > 0)
		{
			// Find the node with the lowest fCost in the open list
			int currentIndex = 0;
			for (int i = 1; i < openList.length; i++)
			{
				LowLevelNode@ a = openList[i];
				LowLevelNode@ b = openList[currentIndex];
				if (a.fCost() < b.fCost() || (a.fCost() == b.fCost() && a.hCost < b.hCost))
				{
					currentIndex = i;
				}
			}

			LowLevelNode@ currentNode = openList[currentIndex];

			// Check if the target is reached
			if ((currentNode.position - target).Length() < 15.0f)
			{
				// Reconstruct best path
				LowLevelNode@ current = currentNode;
				while (current !is null)
				{
					path.insertAt(0, current.position);
					@current = current.parent;
				}

				return;
			}

			openList.removeAt(currentIndex);
			closedList.set(currentNode.position.toString(), @currentNode);

			for (u8 i = 0; i < 4; i++)
			{
				Vec2f neighborPos = currentNode.position + cardinalDirections[i];
				if (closedList.exists(neighborPos.toString())) continue; // Skip if already evaluated

				if (!isPathable(neighborPos, currentNode.position)) continue;

				if ((neighborPos - start).Length() > maximum_pathing_distance_low_level) continue;

				// Check if neighbor is in the open list
				LowLevelNode@ neighborNode = null;
				for (uint j = 0; j < openList.length; j++)
				{
					if (openList[j].position == neighborPos)
					{
						@neighborNode = openList[j];
						break;
					}
				}

				const f32 underwaterPenalty = isUnderwater(currentNode.position) ? 60 : 0;
				const f32 groundPenalty = isGrounded(neighborPos) ? 0 : 40;
				const f32 tentativeGCost = currentNode.gCost + groundPenalty + underwaterPenalty;

				if (neighborNode is null)
				{
					// Add new neighbor to the open list
					openList.push_back(LowLevelNode(neighborPos, tentativeGCost, manhattan(neighborPos, target), currentNode));
				}
				else if (tentativeGCost < neighborNode.gCost)
				{
					// Update existing node with better gCost
					neighborNode.gCost = tentativeGCost;
					@neighborNode.parent = currentNode;
				}
			}
		}
	}

	// Determines if a 2x2 area can be pathed through
	bool isPathable(Vec2f&in tilePos, Vec2f&in previousPos)
	{
		for (u8 i = 0; i < 4; i++)
		{
			if (map.isTileSolid(tilePos + walkableDirections[i])) return false;
		}

		CBlob@[] blobs;
		Vec2f tile(1, 1);
		if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				CShape@ shape = b.getShape();
				if (!shape.getConsts().collidable || !shape.isStatic() || !blob.doesCollideWithBlob(b)) continue;

				if (b.hasTag("door")) // Doors can only be pathed through if its our team or neutral
				{
					const u8 door_team = b.getTeamNum();
					if (door_team != blob.getTeamNum() && door_team != 255)
					{
						return false;
					}
					continue;
				}

				if (b.isPlatform()) // Platforms can only be pathed through if we arent going against it
				{
					if (b.getName() == "bridge") continue;
					ShapePlatformDirection@ plat = shape.getPlatformDirection(0);
					Vec2f dir = plat.direction;
					if (!plat.ignore_rotations) dir.RotateBy(b.getAngleDegrees());
					if (Maths::Abs(dir.AngleWith(b.getPosition() - previousPos)) > plat.angleLimit)
					{
						return false;
					}
					continue;
				}

				return false;
			}
		}

		return true;
	}

	// Determines if a 2x2 area is 'stable'
	bool isGrounded(Vec2f&in tilePos)
	{
		// Ensure there is ground beneath the 2x2 tile area
		if (map.isTileSolid(tilePos + Vec2f(-halfsize, tilesize + halfsize))) return true;
		if (map.isTileSolid(tilePos + Vec2f(halfsize, tilesize + halfsize)))  return true;

		if (map.isInWater(tilePos)) return true;

		CBlob@[] blobs;
		Vec2f tile(halfsize, halfsize);
		if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				if (b.getShape().getVars().isladder) return true; // Ladders count as grounded
			}
		}

		return false;
	}

	bool isUnderwater(Vec2f&in tilePos)
	{
		for (u8 i = 0; i < 4; i++)
		{
			if (!map.isInWater(tilePos + walkableDirections[i])) return false;
		}
		return true;
	}


	/// Movement

	void SetSuggestedAimPos()
	{
		Vec2f pos = blob.getPosition();
		Vec2f target_aim = Vec2f_zero;

		if (waypoints.length > 1 && (pos - waypoints[1]).Length() > 32.0f)
			target_aim = waypoints[1];
		else if (waypoints.length > 0 && (pos - waypoints[0]).Length() > 32.0f)
			target_aim = waypoints[0];
		else if (path.length > 0 && (pos - path[path.length - 1]).Length() > 20.0f)
			target_aim = path[path.length - 1];

		if (target_aim != Vec2f_zero)
		{
			blob.setAimPos(Vec2f_lerp(blob.getAimPos(), target_aim, 0.25f));
		}
	}

	void SetSuggestedKeys()
	{
		Vec2f position = blob.getPosition();
		if (!isPathing())
		{
			blob.setKeyPressed(key_left, false);
			blob.setKeyPressed(key_right, false);
			blob.setKeyPressed(key_up, isUnderwater(position));
			blob.setKeyPressed(key_down, false);
		}

		if (path.length == 0 && waypoints.length > 0)
		{
			path.push_back(waypoints[0]);
		}

		if (path.length == 0) return;

		Vec2f distance = path[0] - position;
		Vec2f direction = distance;
		direction.Normalize();

		blob.setKeyPressed(key_up, direction.y < -0.35f);
		blob.setKeyPressed(key_down, direction.y > 0.5f);

		if (WallJump(direction, distance)) return;

		if (ClimbWall(direction, distance)) return;

		if (JumpOverHole(direction, distance)) return;

		blob.setKeyPressed(key_left, direction.x < -0.5f);
		blob.setKeyPressed(key_right, direction.x > 0.5f);
	}

	bool WallJump(Vec2f&in direction, Vec2f&in distance)
	{
		if (path.length <= 1) return false;

		Vec2f path_direction = path[0] - path[1];
		path_direction.Normalize();

		if (path_direction.y <= 0 || path_direction.x != 0) return false;

		if (blob.isOnLadder() || blob.isInWater()) return false;

		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars)) return false;

		if (moveVars.walljumped_side <= 0) return false;

		const bool left = moveVars.walljumped_side == Walljump::LEFT || moveVars.walljumped_side == Walljump::JUMPED_LEFT;
		const bool right = moveVars.walljumped_side == Walljump::RIGHT || moveVars.walljumped_side == Walljump::JUMPED_RIGHT;

		const int sign = left ? 1 : -1;
		Vec2f end = path[0] + Vec2f(tilesize * 6 * sign, 0);

		// Find the next wall to jump off of
		if (map.rayCastSolid(path[0], end))
		{
			blob.setKeyPressed(key_up, true);
			blob.setKeyPressed(key_down, false);
			blob.setKeyPressed(key_right, left);
			blob.setKeyPressed(key_left, right);

			if (path[0].y > blob.getPosition().y)
			{
				path.erase(0);
			}

			return true;
		}

		return false;
	}

	bool ClimbWall(Vec2f&in direction, Vec2f&in distance)
	{
		if (direction.y < -0.35f && Maths::Abs(distance.x) < 4.0f && !blob.isOnLadder())
		{
			Vec2f position = blob.getPosition();
			const f32 radius = blob.getRadius();
			bool right = map.isTileSolid(Vec2f(position.x + radius + tilesize, position.y - halfsize)) ||
			             map.isTileSolid(Vec2f(position.x + radius + tilesize, position.y + halfsize));
			bool left  = map.isTileSolid(Vec2f(position.x - radius - tilesize, position.y - halfsize)) ||
			             map.isTileSolid(Vec2f(position.x - radius - tilesize, position.y + halfsize));
			if (right || left)
			{
				if (right && left)
				{
					left = position.x >= path[0].x;
					right = position.x < path[0].x;
				}

				// Move towards the adjacent wall
				blob.setKeyPressed(key_left, left);
				blob.setKeyPressed(key_right, right);
				return true;
			}
		}
		return false;
	}

	bool JumpOverHole(Vec2f&in direction, Vec2f&in distance)
	{
		if (path.length <= 1) return false;

		if (blob.isOnLadder() || blob.isInWater()) return false;

		Vec2f depth = Vec2f(0, tilesize * 4);
		if (path.length > 2 && map.rayCastSolid(path[1], path[1] + depth)) return false;
		if (map.rayCastSolid(path[0], path[0] + depth)) return false;

		Vec2f path_direction = path[0] - path[1];
		path_direction.Normalize();
		if (path_direction.y != 0) return false;

		if (waypoints.length <= 0) return false;

		Vec2f position = blob.getPosition();
		Vec2f distance_from_waypoint = waypoints[0] - path[0];
		if (distance_from_waypoint.y > tilesize * 3) return false;

		blob.setKeyPressed(key_up, true);
		blob.setKeyPressed(key_down, false);
		blob.setKeyPressed(key_left, path_direction.x > 0);
		blob.setKeyPressed(key_right, path_direction.x < 0);

		// Adjust the last path point to the nearest ground for a clean landing
		const int index = path.length - 1;
		path[index] = getJumpLanding(path[index], position);

		// Clear paths that we progress while jumping
		if (path_direction.x > 0 && position.x < path[0].x ||
			path_direction.x < 0 && position.x > path[0].x)
		{
			path.erase(0);

			if (path.length == 1)
			{
				ProgressPath();
			}
		}

		return true;
	}

	Vec2f getJumpLanding(Vec2f&in tilePos, Vec2f&in position)
	{
		if (isGrounded(tilePos) && isPathable(tilePos, position)) return tilePos;

		Vec2f best_position = tilePos;
		f32 closest_dist = 99999.0f;

		const int searchRadius = 3;
		for (int y = -searchRadius; y <= searchRadius; y++)
		{
			for (int x = -searchRadius; x <= searchRadius; x++)
			{
				Vec2f nodePos = tilePos + Vec2f(x * tilesize, y * tilesize);
				if (!isGrounded(nodePos) || !isPathable(nodePos, position)) continue;

				const f32 dist = (nodePos - tilePos).Length();
				if (dist < closest_dist)
				{
					best_position = nodePos;
					closest_dist = dist;
				}
			}
		}
		return best_position;
	}


	/// Rendering

	void Render()
	{
		const SColor col(0xff66C6FF);
		Driver@ driver = getDriver();

		// Draw low-level boundary
		//GUI::DrawCircle(blob.getScreenPos(), maximum_pathing_distance_low_level * getCamera().targetDistance * 3, col);

		// Draw high-level boundary
		//GUI::DrawCircle(blob.getScreenPos(), maximum_pathing_distance_high_level * getCamera().targetDistance * 3, ConsoleColour::ERROR);

		// Draw low-level path
		for (int i = 1; i < path.length; i++)
		{
			Vec2f current = driver.getScreenPosFromWorldPos(path[i]);
			Vec2f previous = driver.getScreenPosFromWorldPos(path[i - 1]);
			GUI::DrawArrow2D(previous, current, col);
		}

		// Draw stuck nodes
		const string[]@ cached_keys = cached_waypoints.getKeys();
		for (int i = 0; i < cached_keys.length; i++)
		{
			CachedWaypoint@ cached_waypoint;
			if (!cached_waypoints.get(cached_keys[i], @cached_waypoint)) continue;

			if (waypoints.length > 0 && waypoints[0] == cached_waypoint.position) continue;

			Vec2f stuck_waypoint = driver.getScreenPosFromWorldPos(cached_waypoint.position);
			GUI::DrawCircle(stuck_waypoint, 10.0f, cached_waypoint.stuck ? ConsoleColour::CRAZY : ConsoleColour::WARNING);
		}

		if (waypoints.length > 0)
		{
			// Draw high level path
			for (int i = 1; i < waypoints.length; i++)
			{
				Vec2f waypoint = driver.getScreenPosFromWorldPos(waypoints[i]);
				GUI::DrawCircle(waypoint, 9.0f, ConsoleColour::RCON);
			}

			// Draw current waypoint goal
			Vec2f next_waypoint = driver.getScreenPosFromWorldPos(waypoints[0]);
			GUI::DrawCircle(next_waypoint, 8.0f, col);
		}
	}
}

shared class CachedWaypoint
{
	Vec2f position;
	u32 time;
	bool stuck;

	CachedWaypoint(Vec2f&in position)
	{
		this.position = position;
		this.time = 1;
		this.stuck = false;
	}
}
