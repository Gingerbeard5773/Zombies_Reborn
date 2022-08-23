void onInit(CBlob@ this)
{
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(-50.0f); //push to background
	getMap().AddMarker(this.getPosition() + Vec2f(0, 20), "zombie_spawn");
}

void onDie(CBlob@ this)
{
	CMap@ map = getMap();
	map.RemoveMarkers("zombie_spawn");
	
	CBlob@[] gates;
	getBlobsByName(this.getName(), @gates);
	
	const u8 gatesLength = gates.length;
	for (u8 i = 0; i < gatesLength; i++)
	{
		CBlob@ gate = gates[i];
		if (gate is this) continue;
		
		map.AddMarker(gate.getPosition() + Vec2f(0, 20), "zombie_spawn");
	}
}
