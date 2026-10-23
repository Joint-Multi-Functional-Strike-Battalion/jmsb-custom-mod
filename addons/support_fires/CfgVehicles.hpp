class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Combo;
        };
        class ModuleDescription;
    };

    // ONE MODULE IS ONE ASSET ON THE SUPPORT PAGE, AND MANY MAY BE PLACED - the
    // JMSB - CAS Drone rule, for fires. No module on the map, no row: a mission
    // without a Cruise Missiles module has no cruise missiles.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59). These are the players' assets; the side
    // is player_side on JMSB - Core, and a loitering munition's prey is the
    // enemy side worked out from the mission's relations, never a field here.
    //
    // WHERE IT IS COMES FROM THE MAP. A battery, a cruise missile launcher and
    // a loitering munition launch site are the module's own position (off the
    // map edge is fine). The target is picked per request on the support page.
    //
    // ARTILLERY IS VIRTUAL (user, 2026-10-20: "the modules should act like
    // Simplex, except arty should be virtual"). No gun aims or fires: every
    // round is spawned on its descent over the target.

    // ----------------------------------------- retired: artillery battery --
    // RETIRED 2026-10-20, KEPT SO PLACED MODULES STILL LOAD. Hidden from Eden
    // and Zeus; a placed one runs as a virtual battery (fnc_moduleArtillery):
    // synced guns, if any, give only the battery's position, gun count and -
    // when Ammunition Per Gun is blank - the rounds their magazines carry, and
    // are otherwise left alone. JMSB - Virtual Artillery is what new missions
    // place.
    class jmfsb_moduleFiresArtillery: Module_F {
        scope = 1;
        scopeCurator = 0;
        displayName = "JMSB - Artillery Battery (retired)";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleArtillery));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_art.paa";

        class Attributes: AttributesBase {
            class callsign: Edit {
                property = QGVAR(artyCallsign);
                displayName = "Callsign";
                tooltip = "What the support page and the radio call this battery.";
                typeName = "STRING";
                defaultValue = "'STEEL'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class ammunition: Edit {
                property = QGVAR(artyAmmunition);
                displayName = "Ammunition Per Gun";
                tooltip = "Rounds PER GUN as class:rounds pairs separated by commas - magazine classes (32Rnd_155mm_Mo_shells:24) or shell classes (Sh_155mm_AMOS:24). Multiplied by the guns synced (4 when none). No gun is loaded: these are the battery's virtual rounds. BLANK: the rounds in the synced guns' artillery magazines; with no guns either, the Virtual Artillery defaults.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('ammunition',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(artyCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after a fire mission ends before the battery can be tasked again.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_COOLDOWN);
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "RETIRED - place JMSB - Virtual Artillery instead. Kept so missions that placed it still load.",
                "",
                "Runs as a virtual battery: no gun aims or fires. Synced artillery, if any, gives only the battery's position, its gun count and (with Ammunition Per Gun blank) the rounds its magazines carry.",
                "",
                "Callsign - What the support page calls it",
                "Ammunition Per Gun - class:rounds per gun; blank reads the synced guns",
                "Cooldown (sec) - Time after a mission before it can be tasked again"
            };
            sync[] = {"AnyVehicle"};
        };
    };

    // --------------------------------------------------- virtual artillery --
    class jmfsb_moduleFiresVirtual: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Virtual Artillery";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleVirtual));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_art.paa";

        class Attributes: AttributesBase {
            class callsign: Edit {
                property = QGVAR(virtualCallsign);
                displayName = "Callsign";
                tooltip = "What the support page and the radio call this battery.";
                typeName = "STRING";
                defaultValue = "'THUNDER'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class guns: Edit {
                property = QGVAR(virtualGuns);
                displayName = "Guns";
                tooltip = "Tubes in the battery. Each fires its own rounds into the sheaf; the support page may fire fewer.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_GUNS);
                expression = QUOTE(_this setVariable [ARR_2('guns',_value)]);
            };
            class heClass: Edit {
                property = QGVAR(virtualHeClass);
                displayName = "HE Shell Class";
                tooltip = "CfgAmmo class of the high-explosive round. BLANK: the battery has no HE.";
                typeName = "STRING";
                defaultValue = "'Sh_155mm_AMOS'";
                expression = QUOTE(_this setVariable [ARR_2('heClass',_value)]);
            };
            class heRounds: Edit {
                property = QGVAR(virtualHeRounds);
                displayName = "HE Rounds";
                tooltip = "HE rounds the battery holds for the whole mission. 0: none. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "96";
                expression = QUOTE(_this setVariable [ARR_2('heRounds',_value)]);
            };
            class smokeClass: Edit {
                property = QGVAR(virtualSmokeClass);
                displayName = "Smoke Shell Class";
                tooltip = "CfgAmmo class of the smoke round. BLANK: no smoke.";
                typeName = "STRING";
                defaultValue = "'Smoke_120mm_AMOS_White'";
                expression = QUOTE(_this setVariable [ARR_2('smokeClass',_value)]);
            };
            class smokeRounds: Edit {
                property = QGVAR(virtualSmokeRounds);
                displayName = "Smoke Rounds";
                tooltip = "Smoke rounds for the whole mission. 0: none. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "24";
                expression = QUOTE(_this setVariable [ARR_2('smokeRounds',_value)]);
            };
            class illumClass: Edit {
                property = QGVAR(virtualIllumClass);
                displayName = "Illumination Class";
                tooltip = "CfgAmmo class of the flare an illumination round releases over the target. BLANK: no illumination.";
                typeName = "STRING";
                defaultValue = "'F_40mm_White_Illumination'";
                expression = QUOTE(_this setVariable [ARR_2('illumClass',_value)]);
            };
            class illumRounds: Edit {
                property = QGVAR(virtualIllumRounds);
                displayName = "Illumination Rounds";
                tooltip = "Illumination rounds for the whole mission. 0: none. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "12";
                expression = QUOTE(_this setVariable [ARR_2('illumRounds',_value)]);
            };
            class clusterClass: Edit {
                property = QGVAR(virtualClusterClass);
                displayName = "Cluster Shell Class";
                tooltip = "Optional. CfgAmmo class of a cluster round, for example Cluster_155mm_AMOS. BLANK: no cluster.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('clusterClass',_value)]);
            };
            class clusterRounds: Edit {
                property = QGVAR(virtualClusterRounds);
                displayName = "Cluster Rounds";
                tooltip = "Cluster rounds for the whole mission. 0: none. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('clusterRounds',_value)]);
            };
            class guidedClass: Edit {
                property = QGVAR(virtualGuidedClass);
                displayName = "Guided Shell Class";
                tooltip = "Optional. CfgAmmo class of a guided round, for example Sh_155mm_AMOS_LG (seeks a laser spot) or Sh_155mm_AMOS_guided (seeks armour). BLANK: no guided.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('guidedClass',_value)]);
            };
            class guidedRounds: Edit {
                property = QGVAR(virtualGuidedRounds);
                displayName = "Guided Rounds";
                tooltip = "Guided rounds for the whole mission. 0: none. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('guidedRounds',_value)]);
            };
            class minRange: Edit {
                property = QGVAR(virtualMinRange);
                displayName = "Minimum Range (m)";
                tooltip = "Closest a target may be to this module. The module is the battery's position - put it where the guns would be, on or off the map. The guns' own minimum (the lowest charge at full elevation) also applies.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MIN_RANGE);
                expression = QUOTE(_this setVariable [ARR_2('minRange',_value)]);
            };
            class maxRange: Edit {
                property = QGVAR(virtualMaxRange);
                displayName = "Maximum Range (m)";
                tooltip = "Furthest a target may be from this module. Also capped by what the muzzle velocity can reach.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_RANGE);
                expression = QUOTE(_this setVariable [ARR_2('maxRange',_value)]);
            };
            class dispersion: Edit {
                property = QGVAR(virtualDispersion);
                displayName = "Dispersion (m)";
                tooltip = "Each round's own error radius around its aim point, on top of the sheaf the support page asks for. Guns are not rifles.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_DISPERSION);
                expression = QUOTE(_this setVariable [ARR_2('dispersion',_value)]);
            };
            // THE TIME OF FLIGHT IS WORKED OUT, NOT TYPED. A vacuum arc from the
            // module to the target gives both the time the rounds take and the
            // angle they come down at; high angle fires the lowest charge that
            // reaches, as a real battery does.
            class muzzleVelocity: Edit {
                property = QGVAR(virtualMuzzleVelocity);
                displayName = "Muzzle Velocity (m/s)";
                tooltip = "Time-of-flight model: the rounds fly a ballistic arc from this module to the target, at this speed on the top charge. High angle fires the lowest charge that reaches. 810 is a 155 mm howitzer, 200 an 82 mm mortar.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MV);
                expression = QUOTE(_this setVariable [ARR_2('muzzleVelocity',_value)]);
            };
            class trajectory: Combo {
                property = QGVAR(virtualTrajectory);
                displayName = "Trajectory";
                tooltip = "HIGH ANGLE: long time of flight, rounds plunge in steeply over cover. LOW ANGLE: short flight, flat descent; a round whose descent a ridge would block comes in high instead.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('trajectory',_value)]);
                class Values {
                    class high { name = "High angle"; value = 1; default = 1; };
                    class low { name = "Low angle"; value = 0; };
                };
            };
            class reload: Edit {
                property = QGVAR(virtualReload);
                displayName = "Reload (sec)";
                tooltip = "Time between one gun's rounds. The support page's INTERVAL adds to it.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_RELOAD);
                expression = QUOTE(_this setVariable [ARR_2('reload',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(virtualCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the last round lands before the battery can be tasked again. Also the wait between REPEAT volleys.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_COOLDOWN);
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            // SIMPLEX'S FIRE MISSION KNOBS: what the request may ask for, and
            // how the battery answers it.
            class roundCooldown: Edit {
                property = QGVAR(virtualRoundCooldown);
                displayName = "Cooldown Per Round (sec)";
                tooltip = "Added to the cooldown for every round the mission fired.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_ROUND_CD);
                expression = QUOTE(_this setVariable [ARR_2('roundCooldown',_value)]);
            };
            class responseMin: Edit {
                property = QGVAR(virtualResponseMin);
                displayName = "Response Time Min (sec)";
                tooltip = "Shortest wait between a fire mission being accepted and the first round leaving - a random time between Min and Max, before any DELAY the request asks for.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('responseMin',_value)]);
            };
            class responseMax: Edit {
                property = QGVAR(virtualResponseMax);
                displayName = "Response Time Max (sec)";
                tooltip = "Longest wait between a fire mission being accepted and the first round leaving.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('responseMax',_value)]);
            };
            class sheafTypes: Edit {
                property = QGVAR(virtualSheafTypes);
                displayName = "Sheaf Types";
                tooltip = "The sheaf types the support page offers, separated by commas: CONVERGED (each round at random inside the sheaf), PARALLEL (guns side by side across the line of fire), BOX (rounds spread over the square), CREEPING (each gun's rounds walk away along the line of fire).";
                typeName = "STRING";
                defaultValue = "'CONVERGED, PARALLEL, BOX, CREEPING'";
                expression = QUOTE(_this setVariable [ARR_2('sheafTypes',_value)]);
            };
            class maxRounds: Edit {
                property = QGVAR(virtualMaxRounds);
                displayName = "Max Rounds Per Gun";
                tooltip = "Most rounds per gun one fire mission may ask for - the top of the ROUNDS PER GUN stepper.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_ROUNDS);
                expression = QUOTE(_this setVariable [ARR_2('maxRounds',_value)]);
            };
            class maxInterval: Edit {
                property = QGVAR(virtualMaxInterval);
                displayName = "Max Interval (sec)";
                tooltip = "Most time the request may add between one gun's rounds - the top of the INTERVAL stepper. 0: no INTERVAL stepper.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_INTERVAL);
                expression = QUOTE(_this setVariable [ARR_2('maxInterval',_value)]);
            };
            class maxDelay: Edit {
                property = QGVAR(virtualMaxDelay);
                displayName = "Max Delay (sec)";
                tooltip = "Most time the request may hold the first round - the top of the DELAY stepper. 0: no DELAY stepper.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_DELAY);
                expression = QUOTE(_this setVariable [ARR_2('maxDelay',_value)]);
            };
            class maxRepeat: Edit {
                property = QGVAR(virtualMaxRepeat);
                displayName = "Max Repeats";
                tooltip = "Most extra volleys one fire mission may ask for - the top of the REPEAT stepper. Each repeat fires once the volley before has landed and the cooldown has passed. 0: no REPEAT stepper.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_REPEAT);
                expression = QUOTE(_this setVariable [ARR_2('maxRepeat',_value)]);
            };
            class coordination: Edit {
                property = QGVAR(virtualCoordination);
                displayName = "Coordination Distance (m)";
                tooltip = "Other artillery within this distance of this battery, carrying the same shell and free, may join its fire missions (the support page's COORDINATE). 0: this battery never coordinates, nor joins another's.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_COORDINATION);
                expression = QUOTE(_this setVariable [ARR_2('coordination',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "THE artillery module. A battery on the support page, on or off the map: no guns exist, the module IS the battery's position. Each round is the shell class itself, spawned high over the target on its descending arc after the time of flight from here, so it is heard coming in. Counter-battery has nothing to find.",
                "",
                "A Simplex fire mission: ordnance, rounds per gun, sheaf type and size, guns, interval, delay, repeat volleys, and coordination with nearby batteries. The target is marked on the map until the mission ends. Rounds are counted per type and run out.",
                "",
                "Callsign - What the support page calls it",
                "Guns - Tubes in the battery",
                "HE, Smoke, Illumination, Cluster, Guided - Shell class and rounds of each; 0 none, -1 unlimited",
                "Minimum / Maximum Range (m) - From this module",
                "Dispersion (m) - Each round's own error",
                "Muzzle Velocity (m/s) - Top charge; time-of-flight model",
                "Trajectory - High or low angle",
                "Reload (sec) - Between one gun's rounds",
                "Cooldown (sec) - After the mission, and between repeats",
                "Cooldown Per Round (sec) - Added per round fired",
                "Response Time Min / Max (sec) - Random wait before the first round",
                "Sheaf Types - Which the support page offers",
                "Max Rounds Per Gun, Max Interval, Max Delay, Max Repeats - Stepper limits; 0 hides a stepper",
                "Coordination Distance (m) - Batteries this close may fire together; 0 never"
            };
        };
    };

    // ----------------------------------------------------- cruise missiles --
    class jmfsb_moduleFiresCruise: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Cruise Missiles";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleCruise));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_naval.paa";

        class Attributes: AttributesBase {
            class callsign: Edit {
                property = QGVAR(cruiseCallsign);
                displayName = "Callsign";
                tooltip = "What the support page and the radio call this launcher.";
                typeName = "STRING";
                defaultValue = "'TRIDENT'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class missiles: Edit {
                property = QGVAR(cruiseMissiles);
                displayName = "Missiles";
                tooltip = "Missiles the launcher holds for the whole mission.";
                typeName = "NUMBER";
                defaultValue = "8";
                expression = QUOTE(_this setVariable [ARR_2('missiles',_value)]);
            };
            class missileClass: Edit {
                property = QGVAR(cruiseMissileClass);
                displayName = "Missile Class";
                tooltip = "CfgAmmo class flown as the missile - a real projectile, seen, heard and interceptable. BLANK: ammo_Missile_Cruise_01, the Mk41 VLS round. Its timeToLive limits the range.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('missileClass',_value)]);
            };
            class warhead: Edit {
                property = QGVAR(cruiseWarhead);
                displayName = "Warhead";
                tooltip = "CfgAmmo class set off at the target in place of the missile's own warhead - for example Cluster_155mm_AMOS for submunitions, or Bo_GBU12_LGB. BLANK: the missile's own.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('warhead',_value)]);
            };
            class salvo: Edit {
                property = QGVAR(cruiseSalvo);
                displayName = "Salvo Size";
                tooltip = "Most missiles one request may launch. The support page picks how many, up to this.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('salvo',_value)]);
            };
            class speed: Edit {
                property = QGVAR(cruiseSpeed);
                displayName = "Cruise Speed (m/s)";
                tooltip = "Speed along the route. 250 is a subsonic cruise missile.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('speed',_value)]);
            };
            class altitude: Edit {
                property = QGVAR(cruiseAltitude);
                displayName = "Cruise Altitude (m)";
                tooltip = "Height above the ground the route is flown at, terrain-following. Lower is harder for air defence to see in time.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('altitude',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(cruiseCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the last missile of a salvo is gone before the launcher can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            // SIMPLEX RUNS A SHIP'S VLS AS ARTILLERY: the same response time,
            // per-round cooldown and delay a battery has.
            class missileCooldown: Edit {
                property = QGVAR(cruiseMissileCooldown);
                displayName = "Cooldown Per Missile (sec)";
                tooltip = "Added to the cooldown for every missile the salvo launched.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('missileCooldown',_value)]);
            };
            class responseMin: Edit {
                property = QGVAR(cruiseResponseMin);
                displayName = "Response Time Min (sec)";
                tooltip = "Shortest wait between a strike being accepted and the first missile leaving - a random time between Min and Max, before any DELAY the request asks for.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('responseMin',_value)]);
            };
            class responseMax: Edit {
                property = QGVAR(cruiseResponseMax);
                displayName = "Response Time Max (sec)";
                tooltip = "Longest wait between a strike being accepted and the first missile leaving.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('responseMax',_value)]);
            };
            class maxDelay: Edit {
                property = QGVAR(cruiseMaxDelay);
                displayName = "Max Delay (sec)";
                tooltip = "Most time the request may hold the launch - the top of the DELAY stepper. 0: no DELAY stepper.";
                typeName = "NUMBER";
                defaultValue = QUOTE(VA_DEF_MAX_DELAY);
                expression = QUOTE(_this setVariable [ARR_2('maxDelay',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "A cruise missile launcher on the support page, at this module's position - a ship or ground site, off the map edge is fine.",
                "",
                "Each missile is a real projectile that flies the whole route: up off the rail, terrain-following at cruise altitude to the target, then a terminal dive. Air defence and active protection can shoot it down. The target is marked on the map until the salvo is gone.",
                "",
                "Callsign - What the support page calls it",
                "Missiles - How many for the whole mission",
                "Missile Class - The CfgAmmo flown; blank for ammo_Missile_Cruise_01",
                "Warhead - CfgAmmo set off at the target; blank for the missile's own",
                "Salvo Size - Most per request",
                "Cruise Speed (m/s) / Cruise Altitude (m) - The route",
                "Cooldown (sec) - After a salvo",
                "Cooldown Per Missile (sec) - Added per missile launched",
                "Response Time Min / Max (sec) - Random wait before the first launch",
                "Max Delay (sec) - Top of the DELAY stepper; 0 hides it"
            };
        };
    };

    // ------------------------------------------------- loitering munitions --
    class jmfsb_moduleFiresLoiter: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Loitering Munitions";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleLoiter));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_uav.paa";

        class Attributes: AttributesBase {
            class callsign: Edit {
                property = QGVAR(loiterCallsign);
                displayName = "Callsign";
                tooltip = "What the support page and the radio call this launch site.";
                typeName = "STRING";
                defaultValue = "'GHOST'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class munitionClass: Edit {
                property = QGVAR(loiterMunitionClass);
                displayName = "Munition Class";
                tooltip = "CfgVehicles class of the air vehicle launched. BLANK: the Switchblade 600 when the Switchblade mod is loaded, otherwise the side's Darter flown as a one-way attack drone.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('munitionClass',_value)]);
            };
            class munitions: Edit {
                property = QGVAR(loiterMunitions);
                displayName = "Munitions";
                tooltip = "Munitions the site holds for the whole mission.";
                typeName = "NUMBER";
                defaultValue = "6";
                expression = QUOTE(_this setVariable [ARR_2('munitions',_value)]);
            };
            class launchSize: Edit {
                property = QGVAR(loiterLaunchSize);
                displayName = "Launch Size";
                tooltip = "Most munitions one request may launch. The support page picks how many, up to this.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('launchSize',_value)]);
            };
            class loiterTime: Edit {
                property = QGVAR(loiterTime);
                displayName = "Loiter Time (sec)";
                tooltip = "How long a munition orbits the area hunting once it arrives. Out of time with nothing found, it self-destructs.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('loiterTime',_value)]);
            };
            class strikeRules: Combo {
                property = QGVAR(loiterStrikeRules);
                displayName = "Strike Rules";
                tooltip = "What a munition may dive on. Only the enemy side (worked out from the mission's side relations) is ever a target.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('strikeRules',_value)]);
                class Values {
                    class both { name = "Vehicles and infantry"; value = 0; default = 1; };
                    class vehicles { name = "Vehicles only"; value = 1; };
                    class infantry { name = "Infantry only"; value = 2; };
                };
            };
            class altitude: Edit {
                property = QGVAR(loiterAltitude);
                displayName = "Loiter Altitude (m)";
                tooltip = "Height above the ground the munition flies to the area and orbits at.";
                typeName = "NUMBER";
                defaultValue = "150";
                expression = QUOTE(_this setVariable [ARR_2('altitude',_value)]);
            };
            class warhead: Edit {
                property = QGVAR(loiterWarhead);
                displayName = "Warhead";
                tooltip = "CfgAmmo class set off when the munition reaches its target or self-destructs. BLANK: the Switchblade's own warhead for a Switchblade, otherwise M_Titan_AP.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('warhead',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(loiterCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the last munition of a launch is gone before the site can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "A loitering munition launch site on the support page, at this module's position.",
                "",
                "Each munition is a real air vehicle: it flies to the target area, orbits it for the loiter time hunting, dives on the best target its strike rules allow, and self-destructs when time runs out. It can be shot down. The hunt area is marked on the map until the last munition is gone; a target further than the munition can fly in its transit time is refused.",
                "",
                "Callsign - What the support page calls it",
                "Munition Class - Blank for the Switchblade 600 (Switchblade mod) or the side's Darter",
                "Munitions - How many for the whole mission",
                "Launch Size - Most per request",
                "Loiter Time (sec) - Time on station",
                "Strike Rules - Vehicles, infantry or both, enemy side only",
                "Loiter Altitude (m) - Height above the ground",
                "Warhead - CfgAmmo set off on the target; blank for the munition's own",
                "Cooldown (sec) - After the last munition is gone"
            };
        };
    };
};
