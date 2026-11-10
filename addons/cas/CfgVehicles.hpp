class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // ONE MODULE IS ONE AIRFRAME ON THE BOARD, AND MANY MAY BE PLACED.
    // Unlike the enemy-drone module - where a second placement would arm the
    // same system twice and it says so - each of these IS an asset: its own
    // callsign, its own airframe, its own approach and its own losses. A
    // mission that wants two Reapers and a Bayraktar places three modules and
    // TAC//SUPPORT lists three assets.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59). player_side on JMSB - Core is the
    // only place allegiance is typed and this reads it. A CAS module belongs
    // to whoever the players are, because the support page is theirs.
    //
    // WHERE THE AIRCRAFT COMES FROM IS THE PLAYER'S CALL, NOT THE MODULE'S.
    // The module is placed for its ATTRIBUTES; the target grid and the ingress
    // and egress bearings are set per request on the support page. That is how
    // Simplex does it, and it is why one placement can run a strike onto any
    // grid on the map instead of only the ground it was dropped next to.
    class jmfsb_moduleCAS: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - CAS Drone";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_plane.paa";

        class Attributes: AttributesBase {
            class droneClass: Edit {
                property = QGVAR(droneClass);
                displayName = "Airframe Class";
                tooltip = "Classname of the fixed-wing drone this asset flies. One class per module; place another module for a second airframe. BLANK: the side's vanilla UCAV.";
                typeName = "STRING";
                control = "jmfsb_ClassPick_Uav_Single";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('droneClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(callsign);
                displayName = "Callsign";
                tooltip = "What the support page and the radio call it. Two modules sharing a callsign are two aircraft with the same name - give each its own.";
                typeName = "STRING";
                defaultValue = "'HAWK'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            // ATTRITION IS THE POINT OF A LIMIT. An asset that comes back for
            // ever is a cheat code with a cooldown on it. One that is gone
            // when it is gone makes shooting it down worth doing, and makes
            // the man on the radio ask whether this grid is worth the
            // airframe. THE RESPAWN COUNT (user, 2026-11-02: "make sure there
            // is a respawn count for each support, default no respawns")
            // replaces Airframes Available: the replacements after the first
            // drone, none by default.
            class respawns: Edit {
                property = QGVAR(respawns);
                displayName = "Respawns";
                tooltip = "How many replacement drones this asset gets after a drone is LOST (shot down). The drone is virtual until tasked and goes home after each run without using one. After a loss the asset reads REARMING for the Respawn Delay; the next tasking then makes a new drone over the module. 0: none - the first drone lost is the asset gone from the support list.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(respawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "Time after a drone is lost before the asset can be tasked again with a new drone - only while Respawns has one left.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class spawnDistance: Edit {
                property = QGVAR(spawnDistance);
                displayName = "Ingress Distance (m)";
                tooltip = "The run-in: an ingress point (or, with none, the module the drone is made over) closer to the target than this is pushed back to it, and the drone runs this far on the egress bearing before the asset is free again. It then flies back to the module and is removed.";
                typeName = "NUMBER";
                defaultValue = "4000";
                expression = QUOTE(_this setVariable [ARR_2('spawnDistance',_value)]);
            };
            class speed: Edit {
                property = QGVAR(speed);
                displayName = "Run Speed (km/h)";
                tooltip = "Speed on the run, capped at the airframe's own maximum - a number larger than the aircraft can fly is simply the aircraft's best.";
                typeName = "NUMBER";
                defaultValue = "400";
                expression = QUOTE(_this setVariable [ARR_2('speed',_value)]);
            };
            // RESPONSE DELAY RETIRED (user, 2026-11-02: "virtual till tasked,
            // then they spawn in"): the drone is made at once when tasked. A
            // mission that set spawnDelay still loads; the value is not read.
            class cooldown: Edit {
                property = QGVAR(cooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after a run finishes before this asset can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            // TERMINAL GUIDANCE IS WHY THE GRID IS ONLY THE START. The request
            // carries a grid; the aircraft looks inside this radius of it for
            // a laser spot or smoke on the way in and shifts onto whichever it
            // finds. That is the JTAC's half of the job, and the reason a
            // strike lands on the building rather than the field beside it.
            class searchRadius: Edit {
                property = QGVAR(searchRadius);
                displayName = "Terminal Search (m)";
                tooltip = "How far from the requested grid the drone accepts a laser spot or smoke as the real target. 0: the grid is final, no terminal guidance.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('searchRadius',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable CAS drone on the support page. Place one module per airframe - many are allowed, and each is its own asset with its own losses.",
                "",
                "VIRTUAL UNTIL TASKED: no drone is up between tasks. A request makes one in the air over the module at its hold altitude, dark, full of fuel and stores; after the task it flies back to the module and is removed.",
                "",
                "The requester sets the TARGET GRID and the INGRESS and EGRESS points. Only a drone LOST uses one of the Respawns.",
                "",
                "ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.",
                "",
                "LOITER holds the drone over the grid instead of striking, and hands the gunner's seat to the ISR operator who asked for it - he needs the UAV operator trait and the isISR variable, no UAV terminal. RTB ends it.",
                "",
                "Flies tactically: no lights, strikes from 4000 m above the terrain.",
                "",
                "Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV",
                "Callsign - What the support page and the radio call it",
                "Respawns - Replacement drones after a drone is lost; 0 for none. Going home uses none",
                "Respawn Delay (sec) - Time after a loss before the asset can be tasked again",
                "Ingress Distance (m) - The run-in floor, and how far past the target it runs before the asset is free again",
                "Run Speed (km/h) - Capped at the airframe's own maximum",
                "Cooldown (sec) - Time after a run before this asset can be tasked again",
                "Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none"
            };
        };
    };
};
