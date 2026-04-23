
void server_SetEnraged(CBlob@ this)
{
	if (!isServer()) return;

	if (this.hasTag("exploding")) return;

	if (this.hasCommandID("client_extinguish") && this.isInWater()) return;

	this.set_bool("exploding", true);

	this.server_SetTimeToDie(5);

	//why the fuck does kag need light on server to work. fuckers
	this.SetLight(true);
	this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
	this.SetLightColor(SColor(255, 211, 121, 224));

	this.SendCommand(this.getCommandID("client_enrage"));
}
