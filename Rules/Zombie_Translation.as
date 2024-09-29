// Zombie Fortress Translations

// Gingerbeard @ September 21 2024
//translated strings for zombies reborn
//this is using shiprekt's translation infrastructure

shared const string Translate(const string&in en, const string&in ru = "")
{
	string text_out = "";
	if (g_locale == "en") text_out = en; //english
	if (g_locale == "ru") text_out = ru; //russian 

	if (text_out.isEmpty()) text_out = en; //default to english if we dont have a translation

	return text_out;
}

namespace Translate
{
	const string

	//gamehelp (Translated)
	ZF   = Translate("ZOMBIE FORTRESS",                                                     "ЗОМБИ КРЕПОСТЬ"),
	Tips = Translate("TIPS",                                                                "СОВЕТЫ"),
	Tip0 = Translate("Build a great castle and endure the masses of zombies!",              "Постройте большой замок и выдержите толпу зомби!"),
	Tip1 = Translate("When night arrives, the undead will appear at these gateways.",       "Когда наступит ночь, нежить появится у этих ворот"),
	Tip2 = Translate("A dead body will transform into a zombie after some time.",           "Труп игрока через некоторое время превратится в зомби"),
	Tip3 = Translate("Use water to temporarily stop a burning wraith.",                     "Используйте воду, чтобы потушить горящего призрака"),
	Tip4 = Translate("Head shots deal additional damage.",                                  "Выстрелы в голову наносят больше урона"),
	Tip5 = Translate("A trader will visit at mid-day if it can land safely.",               "Если зомби немного, торговец прилетит к полудню"),
	Tip6 = Translate("Respawns are instant if there is no zombies during day light.",       "Возрождения происходят мгновенно, если днём нет зомби"),
	Tip7 = Translate("Migrants will come every other day if the undead population is low.", "Мигранты будут приходить к вам через каждый день,\nесли популяция нежити будет низкая"),

	//global messages (Translated)
	Day      = Translate("Day {DAYS}",                                                 "День {DAYS}"),
	GameOver = Translate("Game over! All players perished! You survived {DAYS} days.", "Игра закончена! Все игроки погибли! Вы выживали на протяжении {DAYS} дней."),
	GameWin  = Translate("Day {DAYS} Reached! You win!",                               "День {DAYS} Наступил! Вы выиграли!"),
	Trader   = Translate("A flying merchant has arrived!",                             "Прибыл летающий-торговец!"),
	Sedgwick = Translate("Sedgwick the necromancer has appeared!",                     "Некромант Седжвик появился!"),
	Migrant1 = Translate("A refugee has arrived!",                                     "Прибыл Беженец!"),
	Migrant2 = Translate("Refugees have arrived!",                                     "Прибыли Беженцы!"),
	
	//scrolls
	ScrollClone    = Translate("Use this to duplicate an object you are pointing to.",                         ""),
	ScrollCrate    = Translate("Use this to crate an object you are pointing at.",                             ""),
	ScrollFish     = Translate("Use this to summon a shark.",                                                  ""),
	ScrollFlora    = Translate("Use this to create plants nearby.",                                            ""),
	ScrollFowl     = Translate("Use this to summon a flock of chickens.",                                      ""),
	ScrollRevive   = Translate("Use this near a dead body to ressurect them.\nCan auto-resurrect the holder.", ""),
	ScrollRoyalty  = Translate("Use this to summon a geti.",                                                   ""),
	ScrollSea      = Translate("Use this to generate a source of water.",                                      ""),
	ScrollTeleport = Translate("Use this to teleport to the area you are pointing to.",                        ""),
	ScrollStone    = Translate("Use this to convert nearby stone into thick stone.",                           ""),
	ScrollWisent   = Translate("Use this to summon a bison.",                                                  ""),
	
	//builder (TODO)
	IronBlock      = Translate("Iron Block\nResistant to explosions.",                  "Железный Блок\nВзрывоустойчивый."),
	IronBlockBack  = Translate("Back Iron Wall\nDurable Support.",                      "Железная Стена\nПрочная опора."),
	IronDoor       = Translate("Iron Door\nPlace next to walls.",                       ""),
	IronPlatform   = Translate("Iron Platform\nOne way platform",                       ""),
	Windmill       = Translate("Wind Mill\nA grain mill for producing flour.",          "Мельница\nПревращяет зерно в муку."),
	Kitchen        = Translate("Kitchen\nCreate various foods for healing.",            ""),
	Forge          = Translate("Forge\nSmelt raw ore into ingots.",                     ""),
	Nursery        = Translate("Nursery\nA plant nursery for agricultural purposes.",   ""),
	Armory         = Translate("Armory\nBuild weapons and change your class.",          ""),
	Library        = Translate("Library\nA place of study to obtain new technologies.", ""),
	
	//building
	Factory        = Translate("A generic factory for various items. Requires a free worker to produce items.", ""),
	Dormitory      = Translate("A dorm for recruiting and healing workers. Functions as a respawn point.",      ""),
	
	//vehicleshop
	Bomber         = Translate("A balloon capable of flying. Allows attachments. Press [Space] to drop bombs."        ""),
	Armoredbomber  = Translate("A balloon with protective plating. Allows attachments. Press [Space] to drop bombs.", ""),
	Mountedbow     = Translate("A portable arrow-firing death machine. Can be attached to some vehicles.",            ""),
	Tank           = Translate("A seige tank. Allows attachments.",                                                   ""),
	
	//archershop
	MolotovArrows  = Translate("Molotov arrows to incinerate the enemy.",   ""),
	FireworkArrows = Translate("Firework rockets. Explodes where you aim.", ""),
	
	//kitchen
	Bread          = Translate("Bread\nDelicious crunchy whole-wheat bread.", ""),
	Cake           = Translate("Cake\nFluffy cake made from egg and wheat.",  ""),
	Cookedfish     = Translate("Cooked Fish\nA cooked fish on a stick.",      ""),
	Cookedsteak    = Translate("Cooked Steak\nA meat chop with sauce.",       ""),
	Burger         = Translate("Burger\nSeared meat in a bun!",               ""),
	
	//forge
	IronIngot      = Translate("Iron Ingot\nCan be used to create weapons and equipment",         ""),
	CharCoal       = Translate("Coal\nCan be used for fuel or be used to refine steel.",          ""),
	SteelIngot     = Translate("Steel Ingot\nCan be used to create strong weapons and equipment", ""),
	
	//armory (Translated)
	Scythe         = Translate("Scythe\nA tool for cutting crops fast.\nAllows for grain auto-pickup.",                 "Коса\n"Инструмент для срезания травы быстро.\nПозволяет поднямать зерна автоматически.),
	Crossbow       = Translate("Crossbow\nFires any arrow type.\nHold right mouse button to reload.",                   "Арбалет\nСтреляет Любыми стрелами\nЗажмите ПКМ, чтобы перезарядить."),
	Musket         = Translate("Musket\nFires musket balls.\nHold right mouse button to reload.",                       "Мушкет\nСтреляет патронами для Мушкета.\nЗажмите ПКМ, чтобы перезарядить."),
	MusketBalls    = Translate("Musket Balls\nAmmunition for the Musket.",                                              "Пули Мушкета\nПатроны для Мушкета"),
	Chainsaw       = Translate("Chainsaw\nCuts through wood fast.",                                                     "Бензопила\nРежет дерево быстрее."),
	Molotov        = Translate("Molotov\nA flask of fire which can be thrown at the enemy. Press [Space] to activate.", "Коктейль Молотова\nФляга с горючей жидкостью которую можно бросить во врага. Нажмите [Space] для активации"),
	ScubaGear      = Translate("Scuba Gear\nAllows breathing under water.",                                             "Акваланг\nПозволяет дышать под водой"),
	SteelDrill     = Translate("Steel Drill\nA strong drill that can mine for an extended length of time.",             "Железный Бур\nСильный бур, может копать больше руды."),
	SteelHelmet    = Translate("Steel Helmet\nA durable helmet to protect your head.",                                  "Железный Шлем\nПрочный шлем который защитит вашу голову."),
	SteelArmor     = Translate("Steel Chestplate\nA durable chestplate to protect your body.",                          "Железный Нагрудник\nПрочный нагрудник способный защитить ваше тело."),
	
	//trader
	TradeScrollCarnage  = Translate("Sedgwick really doesn't want me to have this.",            ""),
	TradeScrollMidas    = Translate("Makes the rocks shiny.",                                   ""),
	TradeScrollSea      = Translate("A powerful spell known to flood entire villages.",         ""),
	TradeScrollTeleport = Translate("This one can take you anywhere.",                          ""),
	TradeScrollStone    = Translate("If you need rocks.",                                       ""),
	TradeScrollRevive   = Translate("Bring back a friend of yours, or maybe even yourself.",    ""),
	TradeScrollCrate    = Translate("It can put anything in a box, somehow.",                   ""),
	TradeScrollDupe     = Translate("Long lost magic that appears to make a copy of anything!", ""),
	TradeScrollDrought  = Translate("Vaporizes bodies of water.",                               ""),
	TradeScrollFlora    = Translate("Creates various plants from thin air.",                    ""),
	TradeScrollRoyalty  = Translate("I forgot what this one did.",                              ""),
	TradeScrollWisent   = Translate("Summons a bison. Good for meat!",                          ""),
	TradeScrollFowl     = Translate("If you need some eggs.",                                   ""),
	TradeScrollFish     = Translate("Summons a bloodthirsty shark.",                            ""),
	
	//library
	RequiresTech    = Translate("Requires previous upgrade",                                         ""),
	UpgradeComplete = Translate("{UPGRADE} upgrade complete",                                        ""),
	HardyWheat      = Translate("Hardy Wheat\nWheat can grow on stone and gold.",                    ""),
	PlentifulWheat  = Translate("Plentiful Wheat\nWheat can yield an extra grain.",                  ""),
	Metallurgy      = Translate("Metallurgy\nForging time is halved.",                               ""),
	MetallurgyII    = Translate("Metallurgy II\nForging has a chance to yield an extra ingot.",      ""),
	MetallurgyIII   = Translate("Metallurgy III\nQuarrys have a chance to yield iron ore.",          ""),
	MetallurgyIV    = Translate("Metallurgy IV\nQuarrys have a chance to yield gold ore.",           ""),
	Shrapnel        = Translate("Shrapnel\nBombs and kegs deal more damage.",                        ""),
	Swords          = Translate("Sharpening Stone\nSwords deal an extra +1/2 heart of damage.",      ""),
	SwordsII        = Translate("Damascus Steel\nSwords deal an extra +1/2 heart of damage.",        ""),
	CombatPickaxes  = Translate("Combat Pickaxes\nPickaxes deal an extra +1/2 heart of damage.",     ""),
	BlastShields    = Translate("Blast Shields\nShields are resistant to strong explosions.",        ""),
	Regeneration    = Translate("Regeneration\nSurvivors heal half a heart every day.",              ""),
	RegenerationII  = Translate("Regeneration II\nSurvivors heal an additional heart every day",     "");
}
