// loads a classic KAG .PNG map

#include "BasePNGLoader.as";
#include "MinimapHook.as";

namespace zombie_colors
{
	enum color
	{
		blue_spawn = 0xFF00FFFF,
		red_spawn = 0xFFFF0000
	};
}

class ZombiePNGLoader : PNGLoader
{
	ZombiePNGLoader()
	{
		super();
	}
	
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);
		switch (pixel.color)
		{
			//spawns are overwritten with zombie gateways
			case zombie_colors::blue_spawn:
			case zombie_colors::red_spawn:
				spawnBlob(map, "gateway", offset, 255, true, Vec2f(0, -28));
				autotile(offset);
				break;
		};
	}
};

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING ZOMBIES MAP " + fileName, 0xff66C6FF);

	ZombiePNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map, fileName);
}
