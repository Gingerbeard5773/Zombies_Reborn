const u8 TIME_TO_EXPLODE = 5; //seconds
const s32 TIME_TO_ENRAGE = 45 * 30;

void server_SetEnraged(CBlob@ this, const bool&in enrage = true)
{
	if (!isServer()) return;
	
	if (this.hasTag("exploding") && enrage) return;

	this.set_bool("exploding", enrage);
	this.Sync("exploding", true);
	
	this.server_SetTimeToDie(enrage ? TIME_TO_EXPLODE : -1);

	if (!enrage)
	{
		this.getBrain().SetTarget(null);
		this.set_u8("brain_delay", 250); //do a fake stun
	}
	
	//why the fuck does kag need light on server to work. fuckers
	this.SetLight(enrage);
	this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
	this.SetLightColor(SColor(255, 211, 121, 224));

	CBitStream params;
	params.write_bool(enrage);
	this.SendCommand(this.getCommandID("enrage_client"), params);
}
