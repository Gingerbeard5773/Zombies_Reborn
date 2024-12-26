// Procedural Generation for Zombie Fortress
// Uses Pirate-Rob's generation as a base

#include "CustomTiles.as";
#include "Zombie_StructuresCommon.as";

enum BiomeType
{
	Forest = 0, //forest/normal (grass/trees/bushes/ect)
	Desert,     //desert (grain/more gold)
	Meadow,     //meadow (grass/flowers)
	Swamp,      //swamp (land inline with sea, lots of shallow water
	Caves,      //caves (Big overhead cave/cliff)
	Count
};

const f32 tileSize = 8.0f;

bool loadProceduralGenMap(CMap@ map, int&in map_seed)
{
	if (!isServer()) return true;

	Random r(map_seed);

	map.set_s32("map seed", map_seed);

	Noise@ map_noise = Noise(r.Next());
	Noise@ material_noise = Noise(r.Next());
	
	s32 width = m_width;
	s32 height = m_height;
	s32 MaxLandHeight = 20;
	s32 MinFloorHeight = 10;
	s32 StructureMinCount = 3;
	s32 StructureExtraCount = 1;
	s32 StructureChainCount = 0;

	//LOAD PRESETS FROM CONFIG
	ConfigFile cfg;
	if (cfg.loadFile("MapPresets.cfg"))
	{
		string[] presets;
		cfg.readIntoArray_string(presets, "PRESETS");

		const string preset = presets[r.NextRanged(presets.length)];
		print("PROCEDURAL GENERATION TYPE: "+preset, 0xff66C6FF);

		s32[] vars;
		cfg.readIntoArray_s32(vars, preset);

		width = vars[0];
		height = vars[1];
		MaxLandHeight = vars[2];
		MinFloorHeight = vars[3];
		StructureMinCount = vars[4];
		StructureExtraCount = vars[5];
		StructureChainCount = vars[6];
	}
	
	MinFloorHeight = height - MinFloorHeight;

	map.CreateTileMap(width, height, tileSize, "Sprites/world.png");

	const int SeaLevel = height/5*4;

	//gen heightmap
	int[] heightmap(width);
	
	const int BiomeTypes = 4;
	int[] biome(width);
	
	for (int dbl = 0; dbl < 2; dbl++)
	{
		int LastHeight = height*3/5;
		int Straight = 4;
		int Crazy = 0;
		int Uphill = 0;
		int Downhill = 0;
		int CliffUp = 0;
		int CliffDown = 0;
		int ToSeaLevel = 0;
		int CliffChange = -int(r.NextRanged(10));
		int LastType = 0;
		int CurrentBiome = 2; //Always start with meadow
		int CaveLengthBuffer = 0; //This is to force caves to be above 50 wide
		int SwampDip = 0;
		int start = width/2;
		int add = dbl > 0 ? -1 : 1;

		for (int x = start; true; x += add)
		{
			if (x >= width || x < 0) break;
			
			CaveLengthBuffer += 1;
			
			if (Straight == 0 && Crazy == 0 && Uphill == 0 && Downhill == 0 && CliffUp == 0 && CliffDown == 0 && ToSeaLevel == 0)
			{
				if (LastType == BiomeType::Forest && r.NextRanged(10) == 0)
				{
					CurrentBiome = BiomeType::Caves;
					CaveLengthBuffer = 0;
				}

				if (CaveLengthBuffer > 50 + r.NextRanged(50) && CurrentBiome == BiomeType::Caves)
				{
					CurrentBiome = r.NextRanged(BiomeType::Caves);
					CaveLengthBuffer = 0;
				}
				
				if (CurrentBiome == BiomeType::Swamp && LastHeight != SeaLevel) LastType = 5; //Jump to sea level if swamp
				else if (LastType == BiomeType::Forest) LastType = r.NextRanged(4); //If last was stright, anything but cliff
				else if (LastType == BiomeType::Caves) LastType = 1 + r.NextRanged(3); //If last was cliff, anything but cliffs and straights
				else if (CurrentBiome == BiomeType::Caves) LastType = r.NextRanged(4); //If cave biome, anything but cliff
				else LastType = r.NextRanged(BiomeType::Count); // RANDOM!!!!1!
				
				switch(LastType)
				{
					case BiomeType::Forest: Straight = 1 + r.NextRanged(9);   break;
					case BiomeType::Desert: Crazy = r.NextRanged(20);         break;
					case BiomeType::Meadow: Uphill = 2 + r.NextRanged(13);    break;
					case BiomeType::Swamp: Downhill = 5 + r.NextRanged(15);  break;
					case BiomeType::Caves:
					{
						CurrentBiome = r.NextRanged(BiomeType::Caves); //Cliffs are a good time to do biome changes ;)
						
						if (CurrentBiome != BiomeType::Swamp)
						{
							if (CliffChange == 0)
							{
								if (r.NextRanged(2) == 0) CliffUp = 2 + r.NextRanged(8);
								else CliffDown = 5 + r.NextRanged(10);
							}
							if (CliffChange > 0) CliffDown = 5 + r.NextRanged(10);
							if (CliffChange < 0) CliffUp = 2 + r.NextRanged(8);
							
							CliffChange += CliffUp-CliffDown;
						}
						else
						{
							ToSeaLevel = 100; //Swamps get thier own special cliff code
						}

						break;
					}
					case 5: ToSeaLevel = 100; break;
				}
			}
			
			if (Straight > 0)
			{
				heightmap[x] = LastHeight;
				if (Straight > 4 && r.NextRanged(3) == 0)heightmap[x] += int(r.NextRanged(3))-1;
				Straight--;
			}
			else if (Uphill > 0)
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(3) == 0) heightmap[x] -= r.NextRanged(2);
				Uphill--;
			}
			else if (Downhill > 0)
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(3) == 0) heightmap[x] += r.NextRanged(2);
				Downhill--;
			}
			else if (CliffDown > 0)
			{
				heightmap[x] = LastHeight+(r.NextRanged(4) + 1);
				CliffDown--;
			}
			else if (CliffUp > 0)
			{
				heightmap[x] = LastHeight-(r.NextRanged(4) + 1);
				CliffUp--;
			}
			else if (ToSeaLevel > 0)
			{
				if (LastHeight > SeaLevel - 2 && LastHeight < SeaLevel + 2)
				{
					ToSeaLevel = 0;
					heightmap[x] = SeaLevel;
				}
				else
				{
					if (LastHeight > SeaLevel) heightmap[x] = LastHeight - int(r.NextRanged(4) + 1);
					else heightmap[x] = LastHeight + (r.NextRanged(4) + 1);
					ToSeaLevel--;
				}
			}
			else
			{
				heightmap[x] = LastHeight;
				if (r.NextRanged(2) == 0) heightmap[x] += int(r.NextRanged(3)) - 1;
				if (Crazy > 0) Crazy--;
			}
			
			if (ToSeaLevel == 0 && CurrentBiome == BiomeType::Swamp)
			{
				heightmap[x] = SeaLevel + SwampDip;
				if (r.NextRanged(8) == 0) SwampDip = r.NextRanged(2);
			}
			
			LastHeight = heightmap[x];
			if (LastHeight < MaxLandHeight+1) LastHeight += r.NextRanged(3) + 1;
			if (LastHeight > MinFloorHeight-1) LastHeight -= r.NextRanged(5) + 1;
			biome[x] = CurrentBiome;
		}
	}
	
	s16[][] World;
	
	for (int i = 0; i < width; i++) //Init world grid
	{
		s16[] temp;
		temp.set_length(height);
		World.push_back(temp);
	}
	
	int CaveHeight = 4 + r.NextRanged(12);
	
	for (int i = 0; i < width; i++) //Dirty stones!
	{
		for (int j = 0; j < height; j++)
		{ 
			int FakeCaveHeightMap = heightmap[i];
			
			if (biome[i] == BiomeType::Caves) //Caves need special code~
			{
				//On second note, this code is evil beyond all belief, don't touch it.
				f32 Divide = 1;
				
				if (i > 3 && biome[i-4] != BiomeType::Caves) Divide = 0.8;
				if (i > 2 && biome[i-3] != BiomeType::Caves) Divide = 0.6;
				if (i > 1 && biome[i-2] != BiomeType::Caves) Divide = 0.4;
				if (i > 0 && biome[i-1] != BiomeType::Caves) Divide = 0.2;

				if (i < width-4 && biome[i+4] != BiomeType::Caves) Divide = 0.8;
				if (i < width-3 && biome[i+3] != BiomeType::Caves) Divide = 0.6;
				if (i < width-2 && biome[i+2] != BiomeType::Caves) Divide = 0.4;
				if (i < width-1 && biome[i+1] != BiomeType::Caves) Divide = 0.2;
				
				int Change = 5 + r.NextRanged(2);
				Change += Maths::Abs(12-(i % 24));
				Change = Change/4;
				
				FakeCaveHeightMap = (heightmap[i]-CaveHeight)-(Change*Divide)-5*Divide+1;
				
				if (j > (heightmap[i]-CaveHeight)-(Change*Divide)-5*Divide && j < (heightmap[i]-CaveHeight)+((Change*2+r.NextRanged(4))*Divide)-5*Divide)
				{
					World[i][j] = CMap::tile_ground;
				}
				else
				{
					if (j >= (heightmap[i]-CaveHeight)+((Change*2)*Divide)-5*Divide)
					{
						const int Top = (heightmap[i]-CaveHeight)+((Change*2)*Divide)-5*Divide;
						const int Bottom = heightmap[i];
						const int Length = Bottom - Top;
						if (j <= Top+((Divide)*(Length/2+1)) || j >= Bottom-((Divide)*(Length/2+1)))
						{
							World[i][j] = CMap::tile_ground_back;
						}
					}
				}
			} 
			else
			{
				CaveHeight = 10 + r.NextRanged(6);
			}
			
			const int Depth = j - FakeCaveHeightMap;
			
			if (heightmap[i] <= j)
			{
				World[i][j] = CMap::tile_ground;
			}
			if (World[i][j] == CMap::tile_ground)
			{
				if (Depth > 3)
				{
					if (r.NextRanged(2) == 0)
					{
						switch(r.NextRanged(2))
						{
							case 0: World[i][j] = CMap::tile_stone;    break;
							case 1: World[i][j] = CMap::tile_stone_d1; break;
						}
					}
					else
					{
						const f32 frac = (material_noise.Fractal(i*0.1f,j*0.05f) - 0.5f) * 2.0f;
						if (frac > 0.4)
						{
							World[i][j] = CMap::tile_ironore;
						}
						else if (frac < -0.4)
						{
							World[i][j] = CMap::tile_coal;
						}
					}
				}
				
				if (Depth > 6)
				{
					if (r.NextRanged(3) == 0)
					{
						switch(r.NextRanged(3))
						{
							case 0: World[i][j] = CMap::tile_thickstone;    break;
							case 1: World[i][j] = CMap::tile_thickstone_d1; break;
							case 2: World[i][j] = CMap::tile_thickstone_d0; break;
						}
					}
					else
					{
						const f32 frac = (material_noise.Fractal(i*0.1f,j*0.05f) - 0.5f) * 2.0f;
						if (frac > 0.3) World[i][j] = CMap::tile_ironore;
						else if (frac < -0.3) World[i][j] = CMap::tile_coal;
					}
				}

				if (j > SeaLevel)
				{
					if (r.NextRanged(17) == 0)
					{
						World[i][j] = CMap::tile_gold;
					}
					else if (biome[i] == BiomeType::Desert && r.NextRanged(11) == 0)
					{
						World[i][j] = CMap::tile_gold;
					}
				}
			}
		}
	}

	//erosion of dirt (so that we dont have dirt points)
	for (int i = 1; i < width-1; i++)
	{
		for (int j = 1; j < height-1; j++)
		{
			if (World[i][j] != CMap::tile_ground) continue;

			if (World[i][j-1] != 0) continue;

			if (World[i-1][j] == 0 || World[i+1][j] == 0)
			{
				World[i][j] = -1;
			}
		}
	}

	for (int i = 1; i < width-1; i++) //erode dirt points
	{
		for (int j = 1; j < height-1; j++)
		{ 
			if (World[i][j] == -1) World[i][j] = 0;
		}
	}
	//end of erosion

	int FakeCaveTile = 137;
	int FakeCaveTile2 = 138;
	
	for (int i = 0; i < width; i++)
	{
		if (r.NextRanged(3) == 0)
		{
			const int plusY = r.NextRanged(height);
			if (World[i][plusY] != CMap::tile_empty) World[i][plusY] = FakeCaveTile;
		}
	}
	
	for (int i = 0; i < 5; i++)
	{
		Vec2f WormPos = Vec2f(r.NextRanged(width), height/2);
		Vec2f WormDir = Vec2f(1,0);
		WormDir.RotateBy(45+r.NextRanged(45));
		
		for (int j = 0; j < 200+r.NextRanged(200); j++)
		{
			WormDir.RotateBy(int(r.NextRanged(41))-20);
			WormPos = WormPos + WormDir;
		
			if (WormPos.y < 1 || WormPos.y > height-1 || WormPos.x < 1 || WormPos.x > width-1) break;
			
			if (World[u16(WormPos.x)][u16(WormPos.y)] != 0) World[u16(WormPos.x)][u16(WormPos.y)] = FakeCaveTile2;
		}
	}
	
	for (int i = 2; i < width-2; i++) //Expand caves a bit
	{
		for (int j = 2; j < height-2; j++)
		{
			if (World[i][j] != FakeCaveTile) continue;

			for (int k = 0;k < 10; k++)
			{
				int plusX = int(r.NextRanged(5))-2;
				int plusY = int(r.NextRanged(5))-2;
				if (World[i+plusX][j+plusY] != CMap::tile_empty) World[i+plusX][j+plusY] = FakeCaveTile2;
			}
		}
	}
	
	for (int i = 2; i < width-2; i++) //Expand caves a bit Mooore
	{
		for (int j = 2; j < height-2; j++)
		{
			if (World[i][j] != FakeCaveTile2) continue;

			for (int k = 0; k < 10; k++)
			{
				const int plusX = int(r.NextRanged(5))-2;
				const int plusY = int(r.NextRanged(5))-2;
				if (World[i+plusX][j+plusY] != CMap::tile_empty && World[i+plusX][j+plusY] != FakeCaveTile2)
				{
					World[i+plusX][j+plusY] = FakeCaveTile;
				}
			}
		}
	}
	
	for (int i = 0; i < width; i++) //Replace caves with thier actual backgrounds
	{
		for (int j = 0; j < height; j++)
		{
			if (World[i][j] == FakeCaveTile || World[i][j] == FakeCaveTile2)
			{
				World[i][j] = CMap::tile_ground_back;
			}
		}
	}

	/// STRUCTURES ///
	
	const int NodeOffset = -2 - int(r.NextRanged(3));
	const int NodeSize = 7;

	bool[][] Nodes(width / NodeSize);
	for (int i = 0; i < Nodes.length; i++)
	{
		Nodes[i].resize(height/NodeSize);
	}
	
	for (int i = 1; i < width/NodeSize-1; i++) //Find random suitable nodes
	{
		for (int j = 1; j < height/NodeSize; j++)
		{
			Nodes[i][j] = false;
			
			if (r.NextRanged(j) > (f32(height/NodeSize)*0.7f) || r.NextRanged(15) == 0)
			if (World[i*NodeSize][j*NodeSize+NodeOffset] != 0 && World[i*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[i*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[i*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
			if (World[i*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[i*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
			Nodes[i][j] = true;
		}
	}
	
	for (int i = 2; i < width/NodeSize-2; i++) //Extend nodes left or right
	{
		for (int j = 1; j < height/NodeSize; j++)
		{
			if(!Nodes[i][j]) continue;

			if (r.NextRanged(2) == 0)
			{
				if (World[(i-1)*NodeSize][j*NodeSize+NodeOffset] != 0 && World[(i-1)*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[(i-1)*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[(i-1)*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				if (World[(i-1)*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[(i-1)*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				Nodes[i-1][j] = true;
			}
			else
			{
				if (World[(i+1)*NodeSize][j*NodeSize+NodeOffset] != 0 && World[(i+1)*NodeSize][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize+1][j*NodeSize+NodeOffset] != 0 && World[(i+1)*NodeSize+1][j*NodeSize+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize+1][j*NodeSize+1+NodeOffset] != 0 && World[(i+1)*NodeSize+1][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				if (World[(i+1)*NodeSize][j*NodeSize+1+NodeOffset] != 0 && World[(i+1)*NodeSize][j*NodeSize+1+NodeOffset] != CMap::tile_ground_back)
				Nodes[i+1][j] = true;
			}
		}
	}
	
	for (int i = 1; i < width/NodeSize-1; i++) //Kill any singleton nodes with no connectors :(
	{
		for (int j = 1; j < height/NodeSize; j++)
		{
			if(!Nodes[i][j]) continue;

			if (j < height/NodeSize-1)
			{
				if(!Nodes[i-1][j])
				if(!Nodes[i+1][j])
				if(!Nodes[i][j-1])
				if(!Nodes[i][j+1])
				Nodes[i][j] = false;
			}
			else
			{
				if(!Nodes[i-1][j])
				if(!Nodes[i+1][j])
				if(!Nodes[i][j-1])
				Nodes[i][j] = false;
			}
		}
	}

	for (int i = 1; i < width/NodeSize-1; i++) //Build tunnels from nodes.
	{
		for (int j = 1; j < height/NodeSize; j++)
		{
			if(!Nodes[i][j]) continue;

			World[i*NodeSize][j*NodeSize+NodeOffset]     = GetRandomTunnelBackground(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset]   = GetRandomTunnelBackground(r);
			World[i*NodeSize][j*NodeSize+1+NodeOffset]   = GetRandomTunnelBackground(r);
			World[i*NodeSize+1][j*NodeSize+1+NodeOffset] = GetRandomTunnelBackground(r);
			
			World[i*NodeSize-1][j*NodeSize+NodeOffset]   = GetRandomCastleTile(r);
			World[i*NodeSize-1][j*NodeSize+NodeOffset+1] = GetRandomCastleTile(r);
			World[i*NodeSize+2][j*NodeSize+NodeOffset]   = GetRandomCastleTile(r);
			World[i*NodeSize+2][j*NodeSize+NodeOffset+1] = GetRandomCastleTile(r);
			World[i*NodeSize][j*NodeSize+NodeOffset-1]   = GetRandomCastleTile(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset-1] = GetRandomCastleTile(r);
			World[i*NodeSize][j*NodeSize+NodeOffset+2]   = GetRandomCastleTile(r);
			World[i*NodeSize+1][j*NodeSize+NodeOffset+2] = GetRandomCastleTile(r);
		}
	}
		
	for (int i = 1; i < width/NodeSize-1; i++) //Build tunnels from nodes.
	{
		for (int j = 1; j < height/NodeSize; j++)
		{
			if(!Nodes[i][j]) continue;

			if (Nodes[i+1][j])
			{
				for (int k = 0; k < NodeSize-2; k++)
				{
					World[i*NodeSize+k+2][j*NodeSize+NodeOffset] = GetRandomTunnelBackground(r);
					World[i*NodeSize+k+2][j*NodeSize+1+NodeOffset] = GetRandomTunnelBackground(r);
					
					if (r.NextRanged(3) != 0)World[i*NodeSize+k+2][j*NodeSize+2+NodeOffset] = GetRandomCastleTile(r);
					if (r.NextRanged(3) != 0)World[i*NodeSize+k+2][j*NodeSize-1+NodeOffset] = GetRandomCastleTile(r);
				}
			}
			
			if (j < height/NodeSize-1)
			{
				if (Nodes[i][j+1])
				{
					for (int k = 0; k < NodeSize-2; k++)
					{
						World[i*NodeSize][j*NodeSize+k+2+NodeOffset] = GetRandomTunnelBackground(r);
						World[i*NodeSize+1][j*NodeSize+k+2+NodeOffset] = GetRandomTunnelBackground(r);
						
						if (r.NextRanged(3) != 0) World[i*NodeSize-1][j*NodeSize+k+2+NodeOffset] = GetRandomCastleTile(r);
						if (r.NextRanged(3) != 0) World[i*NodeSize+2][j*NodeSize+k+2+NodeOffset] = GetRandomCastleTile(r);
					}
				}
			}
		}
	}

	bool[] SurfacePlanner(width); //The surface planner
	//Basically, if a building is generated, it sets the area in surface planner to false, so other buildings won't build there.
	//Almost all buildings won't build on/in cave biomes, cause that will heavily screw things up.
	for (int i = 1; i < width; i++)
	{
		SurfacePlanner[i] = true;
	}


	/// PLAYER STRUCTURES
	
	const int SurfaceNodes = width / NodeSize - 1;
	for (int times = 0; times < StructureMinCount + r.NextRanged(1 + StructureExtraCount); times++)
	{
		const int i = 1 + r.NextRanged(SurfaceNodes);
		bool CanBuild = true;

		for (int j = -2; j < 4; j++)
		{
			if (!SurfacePlanner[i*NodeSize+j]) CanBuild = false;
		}

		if (!CanBuild) continue;

		int Highest = height;
		for (int j = -2; j < 4; j++)
		{
			if (Highest > heightmap[i*NodeSize+j]) Highest = heightmap[i*NodeSize+j];
		}

		Vec2f pos(i * NodeSize, Highest);
		LoadChainedStructureToWorld(map, pos, Vec2f(width, height), @World, 1 + StructureChainCount);

		for (int j = -2; j < 4; j++)
		{
			SurfacePlanner[i*NodeSize+j] = false;
		}
	}


	/// WELLS ///

	for (int times = 0; times < 1 + r.NextRanged(4); times++)
	{
		const int i = 1 + r.NextRanged(SurfaceNodes);
		bool CanBuild = true;

		for (int j = -2; j < 4; j++)
		{
			if (!SurfacePlanner[i*NodeSize+j] || biome[i*NodeSize+j] == BiomeType::Caves) CanBuild = false;
		}

		if (!CanBuild) continue;

		int Highest = height;

		for (int j = -2; j < 4; j++)
		{
			if (Highest > heightmap[i*NodeSize+j]) Highest = heightmap[i*NodeSize+j];
		}

		if (Highest >= SeaLevel) continue;
		
		for (int j = 0; j < 5; j++)
		{
			World[i*NodeSize-1][Highest+j-1] = CMap::tile_castle;
			World[i*NodeSize+2][Highest+j-1] = CMap::tile_castle;
			World[i*NodeSize][Highest+j-1] = CMap::tile_castle_back;
			World[i*NodeSize+1][Highest+j-1] = CMap::tile_castle_back;
		}
		
		for (int j = Highest+2; j < height; j++)
		{
			if (World[i*NodeSize][j] == CMap::tile_bedrock || World[i*NodeSize+1][j] == CMap::tile_bedrock) break;

			if (j < Highest+((height-Highest)/2) || r.NextRanged(3) > 0) World[i*NodeSize][j] = GetRandomTunnelBackground(r);
			if (j < Highest+((height-Highest)/2) || r.NextRanged(3) > 0) World[i*NodeSize+1][j] = GetRandomTunnelBackground(r);
			if (r.NextRanged(3) == 0) World[i*NodeSize-1][j] = GetRandomCastleTile(r);
			if (r.NextRanged(3) == 0) World[i*NodeSize+2][j] = GetRandomCastleTile(r);
			
			if (j >= SeaLevel)
			{
				map.server_setFloodWaterWorldspace(Vec2f((i*NodeSize)*tileSize,j*tileSize),true);
				map.server_setFloodWaterWorldspace(Vec2f((i*NodeSize+1)*tileSize,j*tileSize),true);
			}
		}
		
		if (r.NextRanged(2) == 0) //Do we have a lid? As in, has the well been decommisioned?
		{
			World[i*NodeSize][Highest-1] = CMap::tile_wood;
			World[i*NodeSize+1][Highest-1] = CMap::tile_wood;
			
			if (r.NextRanged(2) == 0) server_CreateBlob("bucket",-1,Vec2f((i*NodeSize+1)*tileSize,(Highest-2)*tileSize)); //Place bucket on lid or it's lost :(
		}
		else //Other wise, make a pretty roof!
		{
			const int RoofType = r.NextRanged(2) == 0 ? CMap::tile_wood : CMap::tile_castle;
			const int PillarType = r.NextRanged(2) == 0 ? CMap::tile_wood_back : CMap::tile_castle_back;
			
			World[i*NodeSize-1][Highest-2] = PillarType;
			World[i*NodeSize-1][Highest-3] = PillarType;
			World[i*NodeSize+2][Highest-2] = PillarType;
			World[i*NodeSize+2][Highest-3] = PillarType;
			
			for (int j = 0; j < 4; j++)
			{
				World[i*NodeSize-1+j][Highest-4] = RoofType;
			}
			
			int bucketPos = -2;
			if (r.NextRanged(2) == 0) bucketPos = 4;
			
			server_CreateBlob("bucket", -1, Vec2f((i * NodeSize + bucketPos) * tileSize, (Highest - 1) * tileSize));
		}
	
		for (int j = -2; j < 4; j++)
		{
			SurfacePlanner[i*NodeSize+j] = false;
		}
	}


	/// BEDROCK ///
	const int bed_start = 4;
	const float midpoint = width / 2;
	const int bed_end = 16;
	for (int i = 0; i < width; i++) //Set bedrock at bottom
	{
		const float mid_dist = Maths::Abs(i - midpoint) / width * 2;
		for (int j = 0; j < height; j++)
		{
			const f32 frac = map_noise.Fractal(i / tileSize, 0) * tileSize * (1 - mid_dist);
			const int curve = Maths::Min(bed_end, Maths::Pow(mid_dist * 1.2f, 5.0f) * 9);
			if (height - j < bed_start + curve + frac || ((1 - mid_dist) * width <= 3 && height - j <= 9))
			{
				World[i][j] = CMap::tile_bedrock;
				map.server_setFloodWaterWorldspace(Vec2f(i*tileSize, j*tileSize), false);
			}
		}
	}


	/// NATURE ///
	
	for (int i = 0; i < width; i++) //Plants \o/
	{
		for (int j = 0; j < height-1; j++)
		{
			if (World[i][j] == 0 && World[i][j+1] == CMap::tile_ground)
			{
				Vec2f pos(i*tileSize, j*tileSize);
				if (biome[i] == BiomeType::Swamp)
				{
					if (r.NextRanged(10) == 0)
					{
						const string tree_name = r.NextRanged(2) == 0 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, pos);
					}
					if (r.NextRanged(2) == 0)
					{
						server_CreateBlob("bush", -1, pos);
					}
				}
				
				if (j < SeaLevel)
				{
					if ((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(2) == 0) //Grass
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4);
					}

					if (biome[i] == BiomeType::Meadow || biome[i] == BiomeType::Swamp) //Grass
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4);
					}

					if ((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(10) == 0) //Trees
					{
						const string tree_name = j < height/3 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, pos);
					}

					//Rare chance for trees in meadows. This is incase world gen screws up and decides only meadows.
					if (biome[i] == BiomeType::Meadow && r.NextRanged(30) == 0)
					{
						const string tree_name = j < height/3 ? "tree_pine" : "tree_bushy";
						SpawnTree(tree_name, pos);
					}

					if ((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(20) == 0) //Flowers
					{
						SpawnPlant("flowers", pos);
					}

					if ((biome[i] == BiomeType::Forest || biome[i] == BiomeType::Caves) && r.NextRanged(3) == 0) //Bushes
					{
						server_CreateBlob("bush", -1, pos);
						
						if (r.NextRanged(10) == 0)
						{
							SpawnPlant("flowers", pos);
						}
					}
					
					if (biome[i] == BiomeType::Desert || r.NextRanged(3) == 0) //Grain grows in the desert cause it's hipster like that.
					{
						if (r.NextRanged(10) == 0)
						{
							SpawnPlant("grain_plant", pos);
						}
					}
					
					if (biome[i] == BiomeType::Meadow && r.NextRanged(3) == 0) //LOTSA FLOWERS!! @.@
					{
						SpawnPlant("flowers", pos);
						
						if (r.NextRanged(5) == 0)
						{
							server_CreateBlob("bush", -1, pos);
						}
					}
				}
				else if (j == SeaLevel)
				{
					if (biome[i] == BiomeType::Swamp)
					{
						World[i][j] = CMap::tile_grass + r.NextRanged(4); //Grass
						map.server_setFloodWaterWorldspace(pos, true);
					}
				}
				
				break;
			}
		}
	}
	
	for (int i = 0; i < width; i++) //Start water dirt
	{
		for (int j = 0; j < height; j++)
		{
			if (World[i][j] == 0 && j >= SeaLevel)
			{
				if (i > 0 && World[i-1][j] != 0 && World[i-1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
				if (j < height-2 && World[i][j+1] != 0 && World[i][j+1] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
				if (i < width-2 && World[i+1][j] != 0 && World[i+1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
					World[i][j] = CMap::tile_ground_back;
			}
		}
	}
	
	for (int k = 0; k < 8; k++)
	{
		for (int i = 1; i < width-1; i++) //Grow dirt in water
		{
			for (int j = SeaLevel+1; j < height-1; j++)
			{
				if (World[i][j] == CMap::tile_ground_back && r.NextRanged(4) == 0)
				{
					if (World[i-1][j] == 0 && r.NextRanged(2) == 0) World[i-1][j] = CMap::tile_ground_back;
					if (World[i][j+1] == 0 && r.NextRanged(2) == 0) World[i][j+1] = CMap::tile_ground_back;
					if (World[i+1][j] == 0 && r.NextRanged(2) == 0) World[i+1][j] = CMap::tile_ground_back;
					if (World[i][j-1] == 0 && r.NextRanged(2) == 0) World[i][j-1] = CMap::tile_ground_back;

					if (World[i][j+1] != 0 && World[i][j+1] != CMap::tile_ground_back)
					if (World[i][j-1] == 0 || World[i][j-2] == 0 || World[i][j-3] == 0 || World[i][j-4] == 0 || World[i][j-5] == 0)
					if (r.NextRanged(7) == 0)
					{
						Vec2f pos(i*tileSize, j*tileSize);
						//Small chance for bushes "seaweed"
						server_CreateBlob("bush", -1, pos);

						if (r.NextRanged(10) == 0) //Small chance for shark, otherwise, fishies!
						{
							server_CreateBlob("shark", -1, pos);
						}
						else
						{
							server_CreateBlob("fishy", -1, pos);
						}
						map.server_setFloodWaterWorldspace(pos, true);
					}
				}
			}
		}
	}

	for (int j = 0; j < height; j++) //finally set the tiles
	{
		const bool belowSea = (j >= SeaLevel);
		for (int i = 0; i < width; i++)
		{
			Vec2f pos(i * tileSize, j * tileSize);
			const u16 tile = World[i][j];
			map.server_SetTile(pos, tile);

			if (tile != 0 || !belowSea) continue;

			map.server_setFloodWaterWorldspace(pos, true);
			if (i > 0 && World[i - 1][j] != 0 && World[i - 1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
				map.server_SetTile(pos, CMap::tile_ground_back);
			if (j < height - 1 && World[i][j + 1] != 0 && World[i][j + 1] != CMap::tile_ground_back && r.NextRanged(2) == 0)
				map.server_SetTile(pos, CMap::tile_ground_back);
			if (i < width - 1 && World[i + 1][j] != 0 && World[i + 1][j] != CMap::tile_ground_back && r.NextRanged(2) == 0)
				map.server_SetTile(pos, CMap::tile_ground_back);
		}
	}

	return true;
}

CBlob@ SpawnPlant(const string&in name, Vec2f pos)
{
	CBlob@ plant = server_CreateBlobNoInit(name);
	if (plant !is null)
	{
		plant.Tag("instant_grow");
		plant.setPosition(pos);
		plant.Init();
	}
	return plant;
}

CBlob@ SpawnTree(const string&in name, Vec2f pos)
{
	CBlob@ tree = server_CreateBlobNoInit(name);
	if (tree !is null)
	{
		tree.Tag("startbig");
		tree.setPosition(pos + Vec2f(4, 4));
		tree.Init();
	}
	return tree;
}

int GetRandomTunnelBackground(Random@ r)
{
	switch(r.NextRanged(4))
	{
		case 0: return CMap::tile_ground_back;
		case 1: return CMap::tile_ground_back;
		case 2: return CMap::tile_castle_back;
		case 3: return CMap::tile_castle_back_moss;
	}
	return CMap::tile_ground_back;
}

int GetRandomCastleTile(Random@ r)
{
	switch(r.NextRanged(2))
	{
		case 0: return CMap::tile_castle;
		case 1: return CMap::tile_castle_moss;
	}
	return CMap::tile_castle;
}
