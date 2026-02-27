#define CLIENT_ONLY

void onInit(CRules@ this)
{
	Driver@ driver = getDriver();
	driver.ForceStartShaders();
	driver.SetShader("hq2x", false);
	driver.AddShader("drunk", 10.0f);
	driver.SetShader("drunk", false);
}

void onTick(CRules@ this)
{
	Driver@ driver = getDriver();
	if (!driver.ShaderState()) 
	{
		driver.ForceStartShaders();
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player is getLocalPlayer())
	{
		Driver@ driver = getDriver();
		driver.SetShader("drunk", false);
	}
}
