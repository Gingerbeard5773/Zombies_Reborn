// Gingerbeard @ January 16th, 2025

#define SERVER_ONLY

#include "PathingNodesCommon.as";

void onInit(CRules@ this)
{
	onRestart(this);
}

void onReload(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	HighLevelNode@[][] queued_node_updates;
	this.set("queued_node_updates", @queued_node_updates);

	InitializeNodeMap(this);
	
	CMap@ map = getMap();
	if (!map.hasScript(getCurrentScriptName()))
	{
		map.AddScript(getCurrentScriptName());
	}
}

dictionary visited_nodes;

void onSetTile(CMap@ map, u32 index, TileType newtile, TileType oldtile)
{
	if (map.isTileSolid(newtile) && map.isTileSolid(oldtile)) return;

	onMapTileCollapse(map, index);
}

void onMapFloodLayerUpdate(CMap@ map, s32 index) //STAGING ONLY as of march 6th, 2025
{
	onMapTileCollapse(map, index);
}

bool onMapTileCollapse(CMap@ map, u32 index)
{
	HighLevelNode@[]@ nodeMap;
	CRules@ rules = getRules();
	if (!rules.get("node_map", @nodeMap)) return true;

	Vec2f position = map.getTileWorldPosition(index);
	HighLevelNode@[] node_updates;
	HighLevelNode@[] nodes = getNodesInRadius(position, node_distance * 1.7f, nodeMap); //2.25f
	for (int i = 0; i < nodes.length; i++)
	{
		HighLevelNode@ node = nodes[i];
		const string node_key = node.original_position.toString();
		if (visited_nodes.exists(node_key)) continue;
		
		visited_nodes.set(node_key, true);
		node_updates.push_back(node);
	}

	if (node_updates.length != 0)
	{
		rules.push("queued_node_updates", node_updates);
	}
	
	return true;
}

void onTick(CRules@ this)
{
	HighLevelNode@[][]@ queued_node_updates;
	if (!this.get("queued_node_updates", @queued_node_updates)) return;

	if (queued_node_updates.length == 0) return;
	
	visited_nodes.deleteAll();
	
	const int index = queued_node_updates.length - 1;
	HighLevelNode@[] node_update = queued_node_updates[index];

	CMap@ map = getMap();

	for (int i = 0; i < node_update.length; i++)
	{
		UpdateNodePosition(node_update[i], map);
	}

	for (int i = 0; i < node_update.length; i++)
	{
		UpdateNodeConnections(node_update[i], map);
	}

	queued_node_updates.erase(index);
}

void InitializeNodeMap(CRules@ this)
{
	HighLevelNode@[] nodeMap;
	this.set("node_map", @nodeMap);

	CMap@ map = getMap();
	Vec2f dim = map.getMapDimensions();

	const Vec2f[] node_directions = { Vec2f(-node_distance, 0), Vec2f(0, -node_distance) };

	HighLevelNode@[] node_update;
	for (u32 y = node_distance; y < dim.y; y += node_distance)
	{
		for (u32 x = node_distance; x < dim.x; x += node_distance)
		{
			Vec2f nodepos = Vec2f(x, y);
			HighLevelNode@ node = HighLevelNode(nodepos);

			for (u32 i = 0; i < node_directions.length; i++)
			{
				Vec2f neighborPos = nodepos + node_directions[i];

				HighLevelNode@ neighborNode = getNodeFromPosition(neighborPos, nodeMap, map);
				if (neighborNode is null) continue;

				// Connect the new node to the neighbor and vice versa
				node.connections.push_back(@neighborNode);
				neighborNode.connections.push_back(@node);
				
				node.original_connections.push_back(@neighborNode);
				neighborNode.original_connections.push_back(@node);
			}

			nodeMap.push_back(node);
			node_update.push_back(node);
		}
	}
	this.push("queued_node_updates", node_update);
}

void UpdateNodeConnections(HighLevelNode@ node, CMap@ map)
{
	node.connections = node.original_connections;

	for (int i = node.connections.length - 1; i >= 0; i--)
	{
		HighLevelNode@ neighbor = node.connections[i];
		if (neighbor.hasFlag(Path::DISABLED) || !canNodesConnect(node, neighbor, map))
		{
			node.connections.erase(i);

			for (int n = neighbor.connections.length - 1; n >= 0; n--)
			{
				if (neighbor.connections[n] !is node) continue;

				neighbor.connections.erase(n);
				break;
			}
		}
	}
}

void UpdateNodePosition(HighLevelNode@ node, CMap@ map)
{
	node.position = node.original_position;
	node.flags = 0;

	const bool passable = isPassable(node.original_position, map);
	if (passable && isSupported(node.original_position, map))
	{
		node.flags |= Path::GROUND;
		return;
	}

	// Look for the nearest passable area in a small radius
	Vec2f dim = map.getMapDimensions();
	const u8 searchRadius = 3;
	Vec2f closestPos = node.original_position;
	f32 closestDistance = 999999.0f;

	for (int y = -searchRadius; y <= searchRadius; y++)
	{
		for (int x = -searchRadius; x <= searchRadius; x++)
		{
			if (x == 0 && y == 0) continue;

			Vec2f neighborPos = node.original_position + Vec2f(x * tilesize, y * tilesize);
			if (isPassable(neighborPos, map) && isSupported(neighborPos, map) && isInMap(neighborPos, dim))
			{
				const f32 distance = (neighborPos - node.original_position).LengthSquared();
				if (distance < closestDistance)
				{
					closestDistance = distance;
					closestPos = neighborPos;
				}
			}
		}
	}

	// If no passable area is found, mark the node as disabled
	if (closestDistance == 999999.0f)
	{
		if (passable)
			node.flags |= Path::AERIAL;
		else
			node.flags = Path::DISABLED;
		return;
	}

	node.position = closestPos;
	node.flags |= Path::GROUND;
}

bool isSupported(Vec2f&in tilePos, CMap@ map)
{
	Vec2f dim = map.getMapDimensions();
	for (u8 i = 0; i < 4; i++)
	{
		// Are we adjacent to solid tiles
		Vec2f checkPos = tilePos + cardinalDirections[i] * 1.5;
		if (checkPos.x < dim.x && map.isTileSolid(checkPos)) return true;
	}

	if (map.isInWater(tilePos + Vec2f(0, tilesize))) return true;

	CBlob@[] blobs;
	Vec2f tile(halfsize, halfsize);
	if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			CShape@ shape = b.getShape();
			if (!shape.isStatic()) continue;

			if (shape.getVars().isladder) return true;

			// Check for adjacent tile-blobs
			if (shape.getConsts().collidable && (b.getPosition() - tilePos).Length() < 13.0f)
			{
				if (b.getName() == "lantern" || b.getName() == "mounted_bow") continue;

				if (b.isPlatform())
				{
					ShapePlatformDirection@ plat = b.getShape().getPlatformDirection(0);
					Vec2f dir = plat.direction;
					if (!plat.ignore_rotations) dir.RotateBy(b.getAngleDegrees());
					if (Maths::Abs(dir.AngleWith(b.getPosition() - tilePos)) > plat.angleLimit)
					{
						return true;
					}
					continue;
				}

				return true;
			}
		}
	}

	return false;
}

bool isInMap(Vec2f&in tilePos, Vec2f&in dim)
{
	return tilePos.x > 0 && tilePos.y > 0 && tilePos.x < dim.x && tilePos.y < dim.y;
}

void onRender(CRules@ this)
{
	if ((!render_paths && g_debug == 0) || g_debug == 5) return;
	
	HighLevelNode@[]@ nodeMap;
	if (!this.get("node_map", @nodeMap)) return;

	SColor nodeColor(255, 0, 255, 0);
	SColor connectionColor(255, 255, 0, 0);
	SColor airColor(255, 160, 160, 160);
	Driver@ driver = getDriver();
	Vec2f center = driver.getScreenCenterPos();
	Vec2f screen_dim = driver.getScreenDimensions();
	
	const u8 render_blacklist = Path::DISABLED | Path::AERIAL; //stops these types of path from rendering

	for (u32 i = 0; i < nodeMap.length; i++)
	{
		HighLevelNode@ node = nodeMap[i];
		if (node is null || node.hasFlag(render_blacklist)) continue;

		Vec2f pos = driver.getScreenPosFromWorldPos(node.position);
		if ((pos - center).Length() > screen_dim.x) continue;

		GUI::DrawCircle(pos, 4.0f, node.hasFlag(Path::AERIAL) ? airColor : nodeColor);

		for (u32 j = 0; j < node.connections.length; j++)
		{
			HighLevelNode@ neighbor = node.connections[j];
			if (neighbor is null || neighbor.hasFlag(render_blacklist)) continue;
			
			Vec2f neighborpos = driver.getScreenPosFromWorldPos(neighbor.position);
			GUI::DrawLine2D(pos, neighborpos, neighbor.hasFlag(Path::AERIAL) || node.hasFlag(Path::AERIAL) ? airColor :connectionColor);
		}
	}
}
