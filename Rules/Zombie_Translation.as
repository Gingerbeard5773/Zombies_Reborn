// Zombie Fortress Translations

// Gingerbeard @ September 21 2024
//translated strings for zombies reborn

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

	//gamehelp
	ZF   = Translate("ZOMBIE FORTRESS",                                                     "ZOMBIE FORTRESS"),
	Tips = Translate("TIPS",                                                                "Советы"),
	Tip0 = Translate("Build a great castle and endure the masses of zombies!",              "Постройте вместе громадный замок,\n\nчтобы после сражаться с ордами нежити!"),
	Tip1 = Translate("When night arrives, the undead will appear at these gateways.",       "С наступленим ночи, мертвецы будут появляться у ваших ворот."),
	Tip2 = Translate("A dead body will transform into a zombie after some time.",           "Тело умершего через некоторое время воскреснет,\n\nобратившись в зомби."),
	Tip3 = Translate("Use water to temporarily stop a burning wraith.",                     "Используйте воду, чтобы потушить горящего призрака."),
	Tip4 = Translate("Head shots deal additional damage.",                                  "Выстрел в голову наносит больше урона"),
	Tip5 = Translate("A trader will visit at mid-day if it can land safely.",               "Вас навестит торговец в полдень, если этот визит\n\nбудет достаточно безопасным для него."),
	Tip6 = Translate("Respawns are instant if there is no zombies during day light.",       "Ваше возрождение произойдет мгновенно,\n\nесли днём не будет зомби"),
	Tip7 = Translate("Migrants will come every other day if the undead population is low.", "Мигранты будут приходить к вам каждый день,\n\nесли численность всей нежити будет минимальной"),
	
	//scoreboard
	ZF2       = Translate("Zombie Fortress",                                  "Zombie Fortress"),
	Manual    = Translate("Press {KEY} to toggle the help manual on/off.",    "Нажмите {KEY} чтобы включить/выключить справочное руководство."),
	DayNum    = Translate("Day: {DAYS}",                                      "День: {DAYS}"),
	Zombies   = Translate("Zombies: {AMOUNT}",                                "Нежити: {AMOUNT}"),
	Survivors = Translate("Survivors",                                        "Выжившие"),

	//respawning
	Respawn0 = Translate("Waiting for dawn...",              "В ожидании рассвета..."),
	Respawn1 = Translate("Waiting to spawn as an undead...", "В ожидании восстания из мертвых..."),
	Respawn2 = Translate("Respawned as {INPUT}",             "Возродиться как {INPUT}"),
	Respawn3 = Translate("Spawn in the sky",                 "Появление в небе"),
	
	//global messages
	Day      = Translate("Day {INPUT}",                                                 "День {INPUT}"),
	Record   = Translate("Day {INPUT}\n\nNew record!",                                  "День {INPUT}\n\nНовый рекорд!"),
	GameOver = Translate("Game over! All players perished! You survived {INPUT} days.", "Конец игры! Все игроки погибли! Вы выжили на протяжении {INPUT} дней."),
	GameWin  = Translate("Day {INPUT} Reached! You win!",                               "День {INPUT} Достигнут! Вы победили!"),
	Trader   = Translate("A flying merchant has arrived!",                              "Прибыл летающий-торговец!"),
	Sedgwick = Translate("Sedgwick the necromancer has appeared!",                      "Некромант Седжвик только что явился!"),
	Migrant1 = Translate("A refugee has arrived!",                                      "Прибыл беженец!"),
	Migrant2 = Translate("Refugees have arrived!",                                      "Беженцы прибывают!"),
	Tim      = Translate("Tim has appeared!",                                           "Тим появился!"),

	//stats
	Stat0 = Translate("Total zombies killed: {INPUT}",   "Больше всех убивал зомби: {INPUT}"),
	Stat1 = Translate("Most blocks placed: {INPUT}",     "Разместил больше всего блоков: {INPUT}"),
	Stat2 = Translate("Most kills: {INPUT}",             "Больше всего убил: {INPUT}"),
	Stat3 = Translate("Most deaths: {INPUT}",            "Больше всего умер: {INPUT}"),
	Stat4 = Translate("All-time record: {INPUT} Days",   "Нынешний рекорд: {INPUT} Дней"),

	//scrolls
	ScrollClone    = Translate("Scroll of Duplication\nUse this to duplicate an object you are pointing to.",                          "Свиток дублирования\nИспользовав единоразово, он клонирует объект, на который вы указываете курсором."),
	ScrollCrate    = Translate("Scroll of Compaction\nUse this to crate an object you are pointing at.",                               "Свиток уплотнения\nИспользовав единоразово, запечатывает в ящик объект на который вы указываете курсором."),
	ScrollFish     = Translate("Scroll of Fish\nUse this to summon a shark.",                                                          "Свиток Рыбы\nИспользовав единоразово, вы призываете морское существо - акулу."),
	ScrollFlora    = Translate("Scroll of Flora\nUse this to create plants nearby.",                                                   "Свиток Флоры\nИспользовав единоразово, рядом с вами вырвутся из под земли плодородные растения."),
	ScrollFowl     = Translate("Scroll of Fowl\nUse this to summon a flock of chickens.",                                              "Свиток Птицы\nИспользовав единоразово, вы призываете стадо кур."),
	ScrollRevive   = Translate("Scroll of Resurrection\nUse this near a dead body to ressurect them.\nCan auto-resurrect the holder.", "Свиток Воскрешения\nИспользуйте этот свиток рядом с мертвым телом, чтобы воскресить его.\nАвтоматически воскрешает владельца."),
	ScrollRoyalty  = Translate("Scroll of Royalty\nUse this to summon a geti.",                                                        "Свиток королевской власти\nИспользовав единоразово, вы призавете Гети."),
	ScrollSea      = Translate("Scroll of Sea\nUse this to generate a source of water.",                                               "Свиток моря\nИспользовав единоразово, создает под вами источник воды."),
	ScrollTeleport = Translate("Scroll of Conveyance\nUse this to teleport to the area you are pointing to.",                          "Свиток телепортации\nИспользовав единоразово, телепортирует вас туда, куда вы указали курсором."),
	ScrollStone    = Translate("Scroll of Quarry\nUse this to convert nearby dirt into stone and iron.",                               "Свиток Карьера\nИспользовав единоразово, превращает обычную почву рядом с вами в жилы камня."),
	ScrollWisent   = Translate("Scroll of Wisent\nUse this to summon a bison.",                                                        "Свиток Зубра\nИспользовав единоразово, вы призываете сухопутное существо - бизона."),
	ScrollHealth   = Translate("Scroll of Health\nUse this to heal yourself and others around you.",                                   "Свиток Здоровья\nИспользовав единоразово, придает жизненную силу, исцеляя вас и всех окружающих."),
	ScrollRepair   = Translate("Scroll of Repair\nUse this to repair everything around you.",                                          "Свиток ремонта\nИспользовав единоразово, ремонтирует строения и блоки, а также все что окружает вас."),
	ScrollCreation = Translate("Scroll of Creation\nUse this to magically construct a structure from thin air.",                       "Свиток Творения\nИспользовав единоразово, волшебным образом сооружает строение из воздуха."),
	ScrollEarth    = Translate("Scroll of Earth\nUse this to fill in dirt background with dirt.",                                      "Свиток Земли\nИспользовав единоразово, заполняет раскопанные блоки почвы."),
	ScrollChaos    = Translate("Scroll of Chaos\nUse this to ???.",                                                                    "Свиток Хаоса\nИспользовав единоразово, свиток не является определенным и может оказаться непредсказуемым."),
	ScrollMidas    = Translate("Scroll of Midas",                                                                                      "Свиток Мидаса"),

	//builder
	IronBlock      = Translate("Iron Block\nResistant to explosions",                  "Железный блок\nВзрывоустойчивый Блок"),
	IronBlockBack  = Translate("Back Iron Wall\nDurable Support",                      "Железная стена\nПрочная опора"),
	IronDoor       = Translate("Iron Door\nPlace next to walls",                       "Железная дверь\nСтавьте возле стены"),
	IronPlatform   = Translate("Iron Platform\nOne way platform\nBlocks water",        "Железная платформа\nОдносторонняя платформа\nБлокирует воду"),
	IronSpikes     = Translate("Iron Spikes\nDurable spikes",                          "Железные шипы\nПрочные шипы"),
	Dirt           = Translate("Dirt\nPlace on existing dirt",                         "Грязь\nПоместить на существующую грязь"),
	Windmill       = Translate("Wind Mill\nA grain mill for producing flour",          "Мельница\nЗерновая мельница для производства муки"),
	Kitchen        = Translate("Kitchen\nCreate various foods for healing",            "Кухня\nГотовьте различную еду для восстановления здоровья и сил"),
	Forge          = Translate("Forge\nSmelt raw ore into ingots",                     "Плавильня\nПереплавляет сырую руду в слитки"),
	Nursery        = Translate("Nursery\nA plant nursery for agricultural purposes",   "Рассадник\nРассадник для сельскохозяйственных культур"),
	Armory         = Translate("Armory\nBuild weapons and change your class",          "Оружейная\nСлужит для создания оружия из слитков, позволяет сменить класс"),
	Library        = Translate("Library\nA place of study to obtain new technologies", "Библиотека\nМесто хранения знаний и открытий, здесь можно освоить новые технологии"),
	
	//workers
	Worker         = Translate("Worker",                           "Работник"),
	AssignWorker   = Translate("Assign Worker",                    "Назначить работника"),
	UnassignWorker = Translate("Unassign Worker",                  "Уволить работника"),
	WorkerRequired = Translate("Requires a worker",                "Требуется работник"),
	RestWorker     = Translate("Rest Worker",                      "Отдыхающий работник"),
	RecruitWorker  = Translate("Recruit a worker for your needs.", "Наймите работника для своих нужд."),
	
	//generic
	PullItems      = Translate("Take items from other storages", "Извлечь предметы\nБерет предметы из других хранилищ."),
	AddFuel        = Translate("Add fuel (Wood or Coal)",        "Добавить топливо (дерево или уголь)\nДобавляет дерево или уголь в качестве топлива."),
	Recipes        = Translate("Recipes",                        "Рецепты\nСписок всех доступных рецептов."),
	SetRecipe      = Translate("Set Recipe",                     "Выбрать рецепт\nИспользует выбранный рецепт."),
	CurrentRecipe  = Translate("Current Recipe",                 "Текущий рецепт\nНынешний выбранный рецепт."),
	Equip          = Translate("Equip {ITEM}",                   "Экипировать {ITEM}"),
	Unequip        = Translate("Unequip {ITEM}",                 "Снять {ITEM}"),

	//building
	Factory        = Translate("A generic factory for various items. Requires a free worker to produce items.", "Общая фабрика для различных вещей. Требуется свободный рабочий для изготовления предметов."),
	Dormitory      = Translate("A dorm for recruiting and healing workers. Functions as a respawn point.",      "Общежитие для набора и лечения рабочих. Это также, место для возрождения и новоприбывших."),

	//factory
	Bigbomb        = Translate("Big Bomb", "Большая бомба"),

	//vehicleshop
	Bomber         = Translate("A balloon capable of flying. Allows attachments. Press [Space] to drop bombs.",                       "Воздушный шар, способный летать. Позволяет устанавливать навесное оборудование. Нажмите [Пробел] для сброса бомб."),
	Armoredbomber  = Translate("Armored Bomber\nA balloon with protective plating. Allows attachments. Press [Space] to drop bombs.", "Бронированный бомбардировщик\nВоздушный шар с защитным покрытием. Позволяет устанавливать навесное оборудование. Нажмите [Пробел] для сброса бомб."),
	Mountedbow     = Translate("A portable arrow-firing death machine. Can be attached to some vehicles.",                            "Стреляющий стрелами портативный механизм смерти. Может быть установлена на некоторые машины."),
	Tank           = Translate("Tank\nA seige tank. Allows attachments.",                                                             "Танк\nОсадный танк. Позволяет устанавливать навесное оборудование."),
	LightBallista  = Translate("Light Ballista\nA portable ballista. Can be attached to some vehicles.",                              "Легкая баллиста\nПередвижная баллиста. Может устанавливаться на некоторые машины."),
	Cannon         = Translate("Cannon\nA cannon that is capable of obliterating any foe. Can be attached to some vehicles.",         "Пушка\nПушка, способная уничтожить любого противника. Может устанавливаться на некоторые машины."),
	Zeppelin       = Translate("Zeppelin\nA sky fortress with many accomodations on board. Functions as a respawn point.",            "Цеппелин\nНебесная крепость с множеством жилых помещений на борту. Служит точкой возрождения."),
	Cannonballs    = Translate("Cannonballs\nCannonballs for the cannon.", "Пушечные ядра\nПушечные ядра для пушки."),

	//archershop
	MolotovArrows  = Translate("Molotov arrows\nFor incinerating the enemy.", "Стрелы Молотова\nДля испепеления врага."),
	FireworkArrows = Translate("Firework rockets\nExplodes where you aim.",   "Фейерверки\nВзрывается там, куда вы целитесь."),

	//kitchen
	Flour          = Translate("Flour",                                       "Мука"),
	Bread          = Translate("Bread\nDelicious crunchy whole-wheat bread.", "Хлеб\nВкусный хрустящий хлеб из цельнозерновой муки."),
	Cake           = Translate("Cake\nFluffy cake made from egg and wheat.",  "Пирог\nПышный пирог из яиц и пшеницы."),
	Cookedfish     = Translate("Cooked Fish\nA cooked fish on a stick.",      "Жареная рыба\nПриготовленная рыба на палочке."),
	Cookedsteak    = Translate("Cooked Steak\nA meat chop with sauce.",       "Жареный стейк\nОтбивная с соусом."),
	Burger         = Translate("Burger\nSeared meat in a bun!",               "Бургер\nОбжареное мясо в булочке!"),

	//forge
	IronOre        = Translate("Iron Ore",                                                        "Железная руда"),
	Coal           = Translate("Coal\nCan be used for fuel or be used to refine steel.",          "Уголь\nМожно использовать в качестве топлива или для очистки стали."),
	IronIngot      = Translate("Iron Ingot\nCan be used to create weapons and equipment",         "Железный слиток\nМожно использовать для создания оружия и снаряжения."),
	SteelIngot     = Translate("Steel Ingot\nCan be used to create strong weapons and equipment", "Стальной слиток\nМожно использовать для создания прочного оружия и снаряжения."),

	//armory
	Scythe         = Translate("Scythe\nA tool for cutting crops fast.\nAllows for grain auto-pickup.",                 "Коса\nИнструмент для быстрого срезания урожая.\nПозволяет поднямать зерна автоматически."),
	Spear          = Translate("Spear\nA long polearm for stabbing from a distance.",                                   "Копье\nДлинное древковое оружие для нанесения ударов на расстоянии."),
	Crossbow       = Translate("Crossbow\nFires any arrow type.\nHold right mouse button to reload.",                   "Арбалет\nСтреляет любыми стрелами\nЗажмите ПКМ, чтобы перезарядить."),
	Musket         = Translate("Musket\nFires musket balls.\nHold right mouse button to reload.",                       "Мушкет\nСтреляет патронами для Мушкета.\nЗажмите ПКМ, чтобы перезарядить."),
	MusketBalls    = Translate("Musket Balls\nAmmunition for the Musket.",                                              "Мушкетные пули\nПатроны для мушкета"),
	Chainsaw       = Translate("Chainsaw\nCuts through wood fast.",                                                     "Бензопила\nРежет дерево быстрее."),
	Molotov        = Translate("Molotov\nA flask of fire which can be thrown at the enemy. Press [Space] to activate.", "Молотов\nФляга с горючей жидкостью которую можно бросить во врага. Нажмите [Space] для активации."),
	ScubaGear      = Translate("Scuba Gear\nAllows breathing under water.",                                             "Акваланг\nПозволяет дышать под водой."),
	HeadLamp       = Translate("Head Lamp\nWearable lantern for easy illumination!",                                    "Наголовный фонарь\nПереносной фонарь для легкого освещения!"),
	SteelDrill     = Translate("Steel Drill\nA strong drill that can mine for an extended length of time.",             "Стальной бур\nМощный бур, способный вести добычу в течение длительного времени."),
	SteelHelmet    = Translate("Steel Helmet\nA durable helmet to protect your head.",                                  "Стальной шлем\nПрочный шлем для защиты вашей головы."),
	SteelArmor     = Translate("Steel Chestplate\nA durable chestplate to protect your body.",                          "Стальной нагрудник\nПрочная нагрудная пластина для защиты вашего тела."),
	Backpack       = Translate("Backpack\nA backpack to carry your belongings.",                                        "Рюкзак\nРюкзак для переноски ваших вещей."),
	Parachutepack  = Translate("Parachute Pack\nAllows you to fall slowly. Press [Shift] to activate.",                 "Парашютный ранец\nПозволяет вам медленно падать. Нажмите [Shift] для активации."),

	//trader
	Buy                 = Translate("Buy {ITEM} ({QUANTITY})",                                  "Купить {ITEM} ({QUANTITY})"),
	Buy2                = Translate("Buy {QUANTITY} {ITEM} for {COINS} $COIN$",                 "Купить {QUANTITY} {ITEM} за {COINS} $COIN$"),
	Sell                = Translate("Sell {ITEM} ({QUANTITY})",                                 "Продать {ITEM} ({QUANTITY})"),
	Sell2               = Translate("Sell {QUANTITY} {ITEM} for {COINS} $COIN$",                "Продать {QUANTITY} {ITEM} за {COINS} $COIN$"),
	InStock             = Translate("{QUANTITY} In stock",                                      "{QUANTITY} В наличии"),
	OutOfStock          = Translate("Out of stock",                                             "Нет в наличии"),

	// scrolls description
	TradeScrollCarnage  = Translate("Sedgwick really doesn't want me to have this.",            "Седжвик действительно не хочет, чтобы это было у меня."),
	TradeScrollMidas    = Translate("Makes the rocks shiny.",                                   "Придает камням блеск."),
	TradeScrollSea      = Translate("A powerful spell known to flood entire villages.",         "Мощное заклинание, способное затопить целые деревни."),
	TradeScrollTeleport = Translate("This one can take you anywhere.",                          "Этот доставит вас куда угодно."),
	TradeScrollStone    = Translate("If you need rocks.",                                       "Если вам нужны камни."),
	TradeScrollRevive   = Translate("Bring back a friend of yours, or maybe even yourself.",    "Воскрешает вашего друга или, может быть, даже вас самих."),
	TradeScrollCrate    = Translate("It can put anything in a box, somehow.",                   "Каким-то образом он может поместить в коробку всё, что угодно."),
	TradeScrollDupe     = Translate("Long lost magic that appears to make a copy of anything!", "Давно утраченная магия, которая, кажется, создает копию чего угодно!"),
	TradeScrollDrought  = Translate("Vaporizes bodies of water.",                               "Испаряет водоёмы."),
	TradeScrollFlora    = Translate("Creates various plants from thin air.",                    "Создает различные растения из воздуха."),
	TradeScrollRoyalty  = Translate("I forgot what this one did.",                              "Я забыл, что оно делает."),
	TradeScrollWisent   = Translate("Summons a bison. Good for meat!",                          "Вызывает бизона. Отлично подходит для забива на мясо!"),
	TradeScrollFowl     = Translate("If you need some eggs.",                                   "Если вам нужно немного яиц."),
	TradeScrollFish     = Translate("Summons a bloodthirsty shark.",                            "Вызывает кровожадную акулу."),
	TradeScrollHealth   = Translate("This one can heal even the worst injuries.",               "Это может залечить даже самые тяжелые травмы."),
	TradeScrollRepair   = Translate("This one will fix up whatever is nearby!",                 "Этот починит всё, что находится поблизости!"),

	//tim
	HolyGrenade     = Translate("Holy Hand Grenade\nDo mot askj me where I got this.,..",   "Святая ручная граната\nНе спрашивайте меня, откуда я это взял..."),
	Tim0            = Translate("I'll be takinge my leave soonm,,..",                       "Я скоро уйду."),
	Tim1            = Translate("Goodbye.",                                                 "Прощай."),
	Tim2            = Translate("Be carefule withe that!!.",                                "Будьте с этим осторожны."),
	Tim3            = Translate("Lotsa of valuables! for sale!",                            "Множество ценных вещей на продажу!"),
	Tim4            = Translate("Hi!!! Buy my stuff! :D",                                   "Здравствуйте, я здесь, чтобы продать свои ценности. Приходите взглянуть!"),

	//library
	Researching     = Translate("Researching - {PERCENT}",      "Исследование - {PERCENT}"),
	Paused          = Translate("Paused - {PERCENT}",           "Остановлено - {PERCENT}"),
	Resume          = Translate("Click to resume",              "Нажмите, чтобы продолжить"),
	Completed       = Translate("Completed",                    "Завершенно"),
	RequiresTech    = Translate("Requires previous technology", "Требуется предыдущая\nтехнология"),
	TechComplete    = Translate("{TECH} technology complete",   "{TECH} технология исследована"),
	ResearchTime    = Translate("Research time: {TIME} days",   "Время исследования: {TIME} Дней"),

	//technology
	Coinage         = Translate("Coinage\nCoins auto-yield 10%.",                                    "Чеканка монет I\nДоход монет составляет 10%."),
	CoinageII       = Translate("Coinage II\nCoins auto-yield 20%.",                                 "Чеканка монет II\nДоход монет составляет 20%."),
	CoinageIII      = Translate("Coinage III\nCoins auto-yield 30%.",                                "Чеканка монет III\nДоход монет составляет 30%."),
	HardyWheat      = Translate("Hardy Wheat\nWheat can grow on stone and ores.",                    "Выносливая пшеница\nПшеница может расти на камнях и рудах."),
	HardyTrees      = Translate("Hardy Trees\nTrees can grow on stone and ores.",                    "Выносливая деревья\nДеревья могут расти на камне и рудах."),
	PlentifulWheat  = Translate("Plentiful Wheat\nWheat can yield an extra grain.",                  "Обилие пшеницы\nПшеница может дать дополнительное зерно при добыче."),
	Metallurgy      = Translate("Metallurgy\n Forging time reduced by 15%.",                         "Металлургия I\nВремя плавления сокращено на 15%."),
	MetallurgyII    = Translate("Metallurgy II\nForging time reduced by 25%.",                       "Металлургия II\nВремя плавления сокращено на 25%."),
	MetallurgyIII   = Translate("Metallurgy III\nForging time reduced by 35%.",                      "Металлургия III\nВремя плавления сокращено на 35%."),
	MetallurgyIV    = Translate("Metallurgy IV\nForging time reduced by 50%.",                       "Металлургия IV\nВремя плавления сокращено на 50%."),
	Refinement      = Translate("Refinement \nForging has a 10% chance to yield an extra ingot.",    "Искусство обработки I\nКузница при работе может произвести дополнительный слиток с шансом в 10%."),
	RefinementII    = Translate("Refinement II\nForging has a 20% chance to yield an extra ingot.",  "Искусство обработки II\nКузница при работе может произвести дополнительный слиток с шансом в 20%."),
	RefinementIII   = Translate("Refinement III\nForging has a 30% chance to yield an extra ingot.", "Искусство обработки III\nКузница при работе может произвести дополнительный слиток с шансом в 30%."),
	RefinementIV    = Translate("Refinement IV\nForging has a 40% chance to yield an extra ingot.",  "Искусство обработки IV\nКузница при работе может произвести дополнительный слиток с шансом в 40%."),
	Extraction      = Translate("Extraction \nQuarrys have a chance to yield iron ore.",             "Добыча ископаемых I\nКарьер во время работы может добыть железную руду."),
	ExtractionII    = Translate("Extraction II\nQuarrys have a chance to yield gold ore.",           "Добыча ископаемых II\nКарьер во время работы может добыть золотую руду."),
	Milling         = Translate("Milling\nWind mills produce 15% more flour.",                       "Переработка зерна I\nВетряные мельницы производят на 15% больше муки."),
	MillingII       = Translate("Milling II\nWind mills produce 15% more flour.",                    "Переработка зерна II\nВетряные мельницы производят на 15% больше муки."),
	MillingIII      = Translate("Milling III\nWind mills produce 20% more flour.",                   "Переработка зерна III\nВетряные мельницы производят на 20% больше муки."),
	Swords          = Translate("Sharpening Stone\nSwords deal +30% damage.",                        "Точильный rамень\nПравильно заточенные мечи наносят на +30% урона больше."),
	SwordsII        = Translate("Damascus Steel\nSwords deal +30% damage.",                          "Дамасская cталь\nМатериал дает лезвию дополнительную остроту, прибавляя +30% к урону."),
	LightArmor      = Translate("Lightweight Armor\nArmor encumbrance -50%.",                        "Легковесная броня\nПластичность и легкость брони увеличивает вашу скорость +50%."),
	CombatPickaxes  = Translate("Combat Pickaxes\nPickaxes deal 2x damage.",                         "Боевые кирки\nКирки наносят в х2 больше урона."),
	LightPickaxes   = Translate("Light Pickaxes\nPickaxe mining speed increased.",                   "Лёгкие кирки\nСкорость добычи с помощью кирки увеличена."),
	PrecisionDrills = Translate("Precision Drilling\nDrills yield 100%.",                            "Мастерство бурения\nБур добывает 100% материала."),
	Architecture    = Translate("Architecture\nBlock placement is faster.",                          "Скорость строительства\nРазмещение блоков происходит быстрее."),
	Supplies        = Translate("Supplies\n+5 stone, +10 wood per resupply.",                        "Снабжение I\n+5 камней, +10 досок к снабжению."),
	SuppliesII      = Translate("Supplies II\n+5 stone, +10 wood per resupply.",                     "Снабжение II\n+5 камней, +10 досок к снабжению."),
	SuppliesIII     = Translate("Supplies III\n+10 stone, +10 wood per resupply.",                   "Снабжение III\n+10 камней, +10 досок к снабжению."),
	Repeaters       = Translate("Repeaters\nCrossbows are automatic.",                               "Повторители\nАвтоматизирует арбалеты"),
	LightBows       = Translate("Light Bows\nArchers fire faster.",                                  "Лёгкие луки\nЛучники стреляют быстрее."),
	DeepQuiver      = Translate("Deep Quiver\nArchers have infinite arrows.",                        "Глубокие колчаны\nУ лучников нескончаемое количество стрел"),
	MachineBows     = Translate("Machine Bows\nMounted Bows fire faster.",                           "Механизированные луки\nСтационарные арбалеты стреляют быстрее."),
	FastBurnPowder  = Translate("Fast-Burning Powder\nMuskets' +25% damage.",                        "Быстросгорающий порох\nУрон от мушкетов возрастает до +25%."),
	HeavyLead       = Translate("Heavy Lead\nMuskets' +45% damage.",                                 "Тяжелый свинец\nУрон от мушкетов увеличивается на 45%."),
	RifledBarrels   = Translate("Rifled Barrels\nMuskets' penetration increased.",                   "Нарезные стволы\nПробиваемость ружей увеличена."),
	Bandoliers      = Translate("Bandoliers\nMuskets' reload twice as fast.",                        "Патронташи\nМушкеты перезаряжаются в два раза быстрее."),
	GreekFire       = Translate("Greek Fire\nIncendiary weapons deal +50% damage.",                  "Греческий огонь\nВоспламеняющее оружие наносит +50% урона."),
	Shrapnel        = Translate("Shrapnel\nExplosives +25% damage.",                                 "Шрапнель I\nВзрывы наносят +25% урона."),
	ShrapnelII      = Translate("Shrapnel II\nExplosives +25% damage.",                              "Шрапнель II\nВзрывы наносят +25% урона."),
	HighExplosives  = Translate("High Explosives\nExplosives' radius increased.",                    "Усиленная взрывчатка\nРадиус действия взрывчатки увеличился."),
	HolyWater       = Translate("Holy Water\nWater bomb radius and stun time 2x.",                   "Святая вода\nРадиус действия водяной бомбы и время оглушения увеличиваются в 2 раза."),
	BlastShields    = Translate("Blast Shields\nShields negate all explosion damage.",               "Взрывоустойчивые щиты\nЩиты устойчивы к сильным взрывам."),
	FlightTuning    = Translate("Flight Tuning\nAerial vehicles fly 25% faster.",                    "Регулировка полёта\nЛетательные машины летают на 25% быстрее."),
	IronChassis     = Translate("Iron Chassis\nVehicles are 25% more durable.",                      "Железное шасси\nТранспортные средства на 25% прочнее."),
	SteelChassis    = Translate("Steel Chassis\nVehicles are 35% more durable.",                     "Стальное шасси\nТранспортные средства на 35% прочнее."),
	TorsionWinch    = Translate("Torsion Winch\nSeige vehicles fire projectiles 35% farther.",       "Закрученная лебедка\nОсадные орудия стреляют снарядами на 35% дальше."),
	SeigeCrank      = Translate("Seige Crank\nSeige vehicles fire 25% faster",                       "Рукоять для осадного орудия\nОсадные орудия стреляют на 25% быстрее."),
	Regeneration    = Translate("Regeneration\nSurvivors heal two hearts every day.",                "Регенерация I\nВыжившие исцеляют два сердца каждый день."),
	RegenerationII  = Translate("Regeneration II\nSurvivors heal four hearts every day.",            "Регенерация II\nВыжившие исцеляют четыре сердца каждый день"),
	RegenerationIII = Translate("Regeneration III\nSurvivors heal six hearts every day.",            "Регенерация III\nВыжившие исцеляют шесть сердца каждый день."),
	ThermalArmor    = Translate("Thermal Armor\nWearing a full set of armor nullifies fire damage.", "Огнеупорная броня\nНошение полного комплекта брони сводит на нет урон от огня."),
	SwiftBearings   = Translate("Swift Bearings\nGround vehicles move 30% faster.",                  "Подшипники\nНаземный транспорт движется на 30% быстрее."),
	Chainmail       = Translate("Chainmail\nKnights take 25% less damage.",                          "Кольчуга\nРыцари получают на 25% меньше урона."),
	LightSwords     = Translate("Light Swords\nUsing a sword is faster.",                            "Легкие мечи\nВзмах меча становится быстрее."),
	Production      = Translate("Production\nFactories +25% production speed.",                      "Производство I\nЗаводы получают +25% к скорости производства."),
	ProductionII    = Translate("Production II\nFactories +25% production speed.",                   "Производство II\nЗаводы получают +25% к скорости производства.");
}

string name(const string&in translated)
{
	const string[]@ tokens = translated.split("\n");
	if (tokens.length == 0) return "FAILED NAME - CONSULT TRANSLATIONS";
	return tokens[0];
}

string desc(const string&in translated)
{
	const int token = translated.findFirst("\n");
	if (token == -1) return "FAILED DESCRIPTION - CONSULT TRANSLATIONS";
	return translated.substr(token + 1);
}
