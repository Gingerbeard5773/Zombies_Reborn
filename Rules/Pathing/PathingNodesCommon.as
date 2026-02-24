// Gingerbeard @ January 16th, 2025

const bool render_paths = false;  // Dev rendering, set to true to see nodes + pathing

const u8 tilesize = 8;
const u8 halfsize = tilesize / 2;

Vec2f[] walkableDirections = { Vec2f(halfsize, halfsize), Vec2f(halfsize, -halfsize), Vec2f(-halfsize, halfsize), Vec2f(-halfsize, -halfsize) };
Vec2f[] cardinalDirections = { Vec2f(tilesize, 0), Vec2f(-tilesize, 0), Vec2f(0, tilesize), Vec2f(0, -tilesize) };

const u32 node_tiles = 4;
const u32 node_distance = tilesize * node_tiles;

enum Path
{
	DISABLED  = 1 << 0,
	GROUND    = 1 << 1,
	AERIAL    = 1 << 2,
	ALL       = GROUND | AERIAL
};

class Node
{
	Vec2f position;   // Grid position
	f32 gCost;        // Cost from the start node
	f32 hCost;        // Heuristic cost to the target node

	f32 fCost() { return gCost + hCost; }
}

class LowLevelNode : Node
{
	LowLevelNode@ parent;  // Parent node for path reconstruction

	LowLevelNode(Vec2f&in pos, const f32&in g, const f32&in h, LowLevelNode@ par)
	{
		position = pos;
		gCost = g;
		hCost = h;
		@parent = par;
	}
}

class HighLevelNode : Node
{
	Vec2f original_position;                // Original position for easy dictionary lookup
	HighLevelNode@[] original_connections;  // Original nodes we are connected to
	HighLevelNode@[] connections;           // Currently connected nodes
	HighLevelNode@ parent;                  // Parent node for path reconstruction
	u8 flags;                               // Sets the type of node that this is

	HighLevelNode(Vec2f&in pos = Vec2f_zero, const u8&in flags = 0)
	{
		original_position = position = pos;
		gCost = 0.0f;
		hCost = 0.0f;
		@parent = null;
		this.flags = flags;
	}
	
	bool hasFlag(const u8&in flag)
	{
		return (flags & flag) != 0;
	}
}

// Gets the node tied to the position
HighLevelNode@ getNodeFromPosition(Vec2f&in position, HighLevelNode@[]@ nodeMap, CMap@ map)
{
	const int grid_width = Maths::Ceil((map.getMapDimensions().x - node_distance) / node_distance);
	const int x = Maths::Ceil(position.x / node_distance) - 1;
	const int y = Maths::Ceil(position.y / node_distance) - 1;

	if (x < 0 || y < 0 || x >= grid_width) return null;

	const int index = y * grid_width + x;
	return (index >= 0 && index < nodeMap.length) ? nodeMap[index] : null;
}

// Gets the closest applicable node to the position
HighLevelNode@ getClosestNode(Vec2f&in position, HighLevelNode@[]@ nodeMap, const u8&in flags = Path::GROUND)
{
	const f32 maxSearchRadius = node_distance * 15.0f; // Maximum radius to avoid excessive searches
	const f32 searchStep = node_distance * 3.0f;       // Step to increase radius gradually
	f32 currentRadius = searchStep;

	while (currentRadius <= maxSearchRadius)
	{
		HighLevelNode@[] nodes = getNodesInRadius(position, currentRadius, nodeMap, flags);
		f32 closestDistance = 999999.0f;
		HighLevelNode@ closestNode = null;

		for (int i = 0; i < nodes.length; i++)
		{
			HighLevelNode@ node = nodes[i];
			const f32 distance = (node.position - position).Length();
			if (distance < closestDistance)
			{
				@closestNode = node;
				closestDistance = distance;
			}
		}

		if (closestNode !is null) return closestNode;

		currentRadius += searchStep;
	}

	return null;
}

// Grabs all applicable nodes within a set radius of your position
HighLevelNode@[] getNodesInRadius(Vec2f&in position, const f32&in radius, HighLevelNode@[]@ nodeMap, const int flags = -1)
{
	CMap@ map = getMap();
	HighLevelNode@[] nodes;
	const int searchRadius = Maths::Ceil(radius / node_distance);

	Vec2f centerNodePos = alignToNodeGrid(position);

	for (int y = -searchRadius; y <= searchRadius; y++)
	{
		for (int x = -searchRadius; x <= searchRadius; x++)
		{
			Vec2f nodePos = centerNodePos + Vec2f(x * node_distance, y * node_distance);
			if ((nodePos - position).LengthSquared() > radius * radius) continue;

			HighLevelNode@ node = getNodeFromPosition(nodePos, nodeMap, map);
			if (node is null) continue;

			if (flags != -1 && !node.hasFlag(flags)) continue;

			nodes.push_back(node);
		}
	}

	return nodes;
}

Vec2f alignToNodeGrid(Vec2f&in position)
{
	const int x = Maths::Round(position.x / node_distance) * node_distance;
	const int y = Maths::Round(position.y / node_distance) * node_distance;
	return Vec2f(x, y);
}

// Determines if two nodes can be connected- calculated by simulating a path between them
bool canNodesConnect(HighLevelNode@ node, HighLevelNode@ neighbor, CMap@ map)
{
	Vec2f start = node.position, target = neighbor.position;

	const bool air = node.hasFlag(Path::AERIAL) || neighbor.hasFlag(Path::AERIAL);
	if ((start - target).LengthSquared() > Maths::Pow(node_distance * 1.7f, 2) && !air) return false;

	Vec2f minBound = Vec2f(Maths::Min(start.x, target.x) - tilesize * 2, Maths::Min(start.y, target.y) - tilesize * 2);
	Vec2f maxBound = Vec2f(Maths::Max(start.x, target.x) + tilesize * 2, Maths::Max(start.y, target.y) + tilesize * 2);
	LowLevelNode@[] openList;
	dictionary openSet;
	dictionary closedList;
	openSet.set(start.toString(), true);
	openList.push_back(LowLevelNode(start, 0, (start - target).LengthSquared(), null));

	while (openList.length > 0)
	{
		int currentIndex = 0;
		for (int i = 1; i < openList.length; i++)
		{
			if (openList[i].hCost < openList[currentIndex].hCost)
			{
				currentIndex = i;
			}
		}

		LowLevelNode@ currentNode = openList[currentIndex];
		if ((currentNode.position - target).LengthSquared() <= 64.0f) return true;

		openList.removeAt(currentIndex);
		openSet.delete(currentNode.position.toString());
		closedList.set(currentNode.position.toString(), @currentNode);

		for (u8 i = 0; i < 4; i++)
		{
			Vec2f neighborPos = currentNode.position + cardinalDirections[i];
			if (closedList.exists(neighborPos.toString())) continue;

			if (neighborPos.x < minBound.x || neighborPos.y < minBound.y || neighborPos.x > maxBound.x || neighborPos.y > maxBound.y) continue;

			if (!isPassable(neighborPos, map)) continue;

			if (!openSet.exists(neighborPos.toString()))
			{
				openList.push_back(LowLevelNode(neighborPos, 0, (neighborPos - target).LengthSquared(), currentNode));
				openSet.set(neighborPos.toString(), true);
			}
		}
	}

	return false;
}

// Determines if the 2x2 area can be passed by a player
bool isPassable(Vec2f&in tilePos, CMap@ map)
{
	for (u8 i = 0; i < 4; i++)
	{
		if (map.isTileSolid(tilePos + walkableDirections[i])) return false;
	}

	CBlob@[] blobs;
	Vec2f tile(2, 2);
	if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			CShape@ shape = b.getShape();
			if (!shape.isStatic() || !shape.getConsts().collidable) continue;

			if (b.hasTag("door") || b.isPlatform()) continue;

			if (b.getName() == "lantern" || b.getName() == "mounted_bow") continue;

			return false;
		}
	}

	return true;
}
