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
            // airframe.
            class airframes: Edit {
                property = QGVAR(airframes);
                displayName = "Airframes Available";
                tooltip = "How many times this drone may be shot down before the asset is expended and leaves the support page for good. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('airframes',_value)]);
            };
            class spawnDistance: Edit {
                property = QGVAR(spawnDistance);
                displayName = "Ingress Distance (m)";
                tooltip = "How far out the drone appears on the requested ingress bearing, and how far it runs on the egress bearing before the asset is free again. It then flies on off the map edge and despawns there.";
                typeName = "NUMBER";
                defaultValue = "4000";
                expression = QUOTE(_this setVariable [ARR_2('spawnDistance',_value)]);
            };
            class altitude: Edit {
                property = QGVAR(altitude);
                displayName = "Attack Altitude (m)";
                tooltip = "Height ABOVE THE TERRAIN (ATL) the run is flown at, so the aircraft climbs with rising ground rather than into it. High enough to live through small arms, low enough to see what it is shooting.";
                typeName = "NUMBER";
                defaultValue = "700";
                expression = QUOTE(_this setVariable [ARR_2('altitude',_value)]);
            };
            class speed: Edit {
                property = QGVAR(speed);
                displayName = "Run Speed (km/h)";
                tooltip = "Speed on the run, capped at the airframe's own maximum - a number larger than the aircraft can fly is simply the aircraft's best.";
                typeName = "NUMBER";
                defaultValue = "400";
                expression = QUOTE(_this setVariable [ARR_2('speed',_value)]);
            };
            class spawnDelay: Edit {
                property = QGVAR(spawnDelay);
                displayName = "Response Delay (sec)";
                tooltip = "Time between the request being accepted and the aircraft appearing. Support that arrives instantly is not support, it is a button.";
                typeName = "NUMBER";
                defaultValue = "30";
                expression = QUOTE(_this setVariable [ARR_2('spawnDelay',_value)]);
            };
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
                "The player sets the TARGET GRID, the INGRESS bearing and the EGRESS bearing on the support page. The drone appears at the ingress distance on that bearing, runs the target, and leaves on the egress bearing - off the map edge, where it despawns.",
                "",
                "ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.",
                "",
                "LOITER holds the drone over the point instead of striking it, and hands the gunner's seat to the ISR operator who asked for it - he needs the UAV operator trait and the isISR variable, no UAV terminal. RTB ends it.",
                "",
                "Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV",
                "Callsign - What the support page and the radio call it",
                "Airframes Available - How many times it may be shot down before the asset is expended; 0 for unlimited",
                "Ingress Distance (m) - How far out it appears, and how far past the target it runs before the asset is free again",
                "Attack Altitude (m) - Height above the terrain (ATL) the run is flown at",
                "Run Speed (km/h) - Capped at the airframe's own maximum",
                "Response Delay (sec) - Time from accepted request to the aircraft appearing",
                "Cooldown (sec) - Time after a run before this asset can be tasked again",
                "Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none"
            };
        };
    };
};
