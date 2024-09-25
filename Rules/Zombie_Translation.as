// Zombie Fortress Translations

// Gingerbeard @ September 21 2024
//translated strings for zombies reborn
//this is using shiprekt's translation infrastructure

shared const string Translate(const string&in en, const string&in ru)
{
	if (g_locale == "en") return en; //english
	if (g_locale == "ru") return ru; //russian 

	return en;
}

namespace Translate
{
	const string
	
	Tip0 = Translate("Build a great castle and endure the masses of zombies!",                "Постройте большой замок и выдержите толпу зомби!"),
	Tip1 = Translate("When night arrives, the undead will appear at these gateways.",         "Когда наступит ночь, нежить появится у этих ворот"),
	Tip2 = Translate("A dead body will transform into a zombie after some time.",             "Труп игрока через некоторое время превратится в зомби"),
	Tip3 = Translate("Use water to temporarily stop a burning wraith.",                       "Используйте воду, чтобы потушить горящего призрака"),
	Tip4 = Translate("Head shots deal additional damage.",                                    "Выстрелы в голову наносят больше урона"),
	Tip5 = Translate("A trader will visit at mid-day if it can land safely.",                 "Если зомби немного, торговец прилетит к полудню"),
	Tip6 = Translate("Respawns are instant if there is no zombies during day light.",         "Возрождения происходят мгновенно, если днём нет зомби"),
	Tip7 = Translate("Migrants will come every other day if the undead population is low.",   "Мигранты будут приходить к вам через каждый день,\nесли популяция нежити будет низкая");
}
