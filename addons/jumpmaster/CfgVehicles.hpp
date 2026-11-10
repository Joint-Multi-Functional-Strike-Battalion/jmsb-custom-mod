class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Combo;
        };
        class ModuleDescription;
    };

    // ONE MODULE IS ONE JUMP AIRCRAFT IN TAC//MSG, AND MANY MAY BE PLACED
    // (user, 2026-11-02: "Jump aircraft module" - class, call sign,
    // altitudes, side; several jump aircraft per side). The same shape as the
    // support modules in addons/support_air. A side with no module keeps its
    // own jump aircraft, flown from the Jumpmaster settings.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59): the side is the side of the units
    // synced to the module, else the players' (FUNC(moduleJump)).
    //
    // VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to
    // be virtual till tasked, then they spawn in at alt over the support
    // module location"): no aircraft until a JUMP REQUEST is accepted; then it
    // is made over the module, 2000 m up, and orbits it for the BOARD; after
    // the run it flies back here and is removed. Where the stick goes is the
    // JUMP REQUEST, never a module field. RESPAWNS (user, 2026-11-02: "make
    // sure there is a respawn count for each support, default no respawns")
    // took Sorties' place and counts losses only; there is no Response Delay.
    class GVAR(moduleJump): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Jump Aircraft";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleJump));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_plane.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QGVAR(jumpAircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft the squad jumps from - a crewed plane or helicopter with seats for the stick. BLANK: the side's cargo aircraft (Blackfish for BLUFOR and independents, Xi'an for OPFOR).";
                typeName = "STRING";
                control = QGVAR(pickAircraft);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(jumpCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//MSG lists it as and what it signs its answers with. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'SKYTRAIN'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class haloAltitude: Edit {
                property = QGVAR(jumpHaloAltitude);
                displayName = "HALO Altitude (m)";
                tooltip = "Height above the terrain of a HALO run, 1000 to 10000.";
                typeName = "NUMBER";
                defaultValue = QUOTE(ALT_FREEFALL_DEFAULT);
                expression = QUOTE(_this setVariable [ARR_2('haloAltitude',_value)]);
            };
            class hahoAltitude: Edit {
                property = QGVAR(jumpHahoAltitude);
                displayName = "HAHO Altitude (m)";
                tooltip = "Height above the terrain of a HAHO run, 1000 to 10000. The stick opens at the aircraft, so the wind carries it from here.";
                typeName = "NUMBER";
                defaultValue = QUOTE(ALT_FREEFALL_DEFAULT);
                expression = QUOTE(_this setVariable [ARR_2('hahoAltitude',_value)]);
            };
            class staticAltitude: Edit {
                property = QGVAR(jumpStaticAltitude);
                displayName = "Static Line Altitude (m)";
                tooltip = "Height above the terrain of a static-line run, 100 to 500. The line pulls the canopy 1 second after exit.";
                typeName = "NUMBER";
                defaultValue = QUOTE(ALT_STATIC_DEFAULT);
                expression = QUOTE(_this setVariable [ARR_2('staticAltitude',_value)]);
            };
            class passes: Edit {
                property = QGVAR(jumpPasses);
                displayName = "Passes By Default";
                tooltip = "Passes over the drop zone, 1 to 4, when the JUMP REQUEST leaves PASSES empty. The stick is split evenly across them.";
                typeName = "NUMBER";
                defaultValue = QUOTE(MODULE_PASSES);
                expression = QUOTE(_this setVariable [ARR_2('passes',_value)]);
            };
            class exit: Combo {
                property = QGVAR(jumpExit);
                displayName = "Exit By Default";
                tooltip = "How the stick leaves when the JUMP REQUEST ticks no EXIT. AUTOMATIC: out at the green light, one man every 0.7 s. MANUAL: each man presses JUMP in his action menu. JUMP is there either way.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('exit',_value)]);
                class Values {
                    class auto { name = "Automatic at the green light"; value = 0; default = 1; };
                    class manual { name = "Manual - each man exits himself"; value = 1; };
                };
            };
            class bay: Combo {
                property = QGVAR(jumpBay);
                displayName = "In The Aircraft";
                tooltip = "SEATS: every man in a cargo seat. STANDING: every man on his feet in the bay, fixed to the hull in two files - for an aircraft whose seats are too few for the stick.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('bay',_value)]);
                class Values {
                    class seats { name = "Seats"; value = 0; default = 1; };
                    class stand { name = "Standing in the bay"; value = 1; };
                };
            };
            class cooldown: Edit {
                property = QGVAR(jumpCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after a run is over before this aircraft takes the next JUMP REQUEST.";
                typeName = "NUMBER";
                defaultValue = QUOTE(MODULE_COOLDOWN);
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawns: Edit {
                property = QGVAR(jumpRespawns);
                displayName = "Respawns";
                tooltip = "How many aircraft may be lost (destroyed, crew dead, or unable to fly) and replaced. Each loss uses one; the next JUMP REQUEST after the Respawn Delay makes a new aircraft. Going home after a run uses none. 0: none - after its first loss the jump aircraft is gone from TAC//MSG.";
                typeName = "NUMBER";
                defaultValue = QUOTE(MODULE_RESPAWNS);
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(jumpRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "Time after an aircraft is lost before the next JUMP REQUEST can make a new one. The row reads REARMING meanwhile.";
                typeName = "NUMBER";
                defaultValue = QUOTE(MODULE_RESPAWN_DELAY);
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            // DRONE ESCORTS (user, 2026-11-02: "drone escorts is based on lz
            // security for helos and always for fix wings";
            // EFUNC(support_air,escortLaunch), the same attributes as the
            // support_air modules).
            class escortPlane: Edit {
                property = QGVAR(jumpEscortPlane);
                displayName = "Fixed-Wing Escort Class";
                tooltip = "The fixed-wing drone a plane's two escorts fly - always, made with it over the module and removed with it. Empty: the side's vanilla UCAV. Not a fixed-wing class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QEGVAR(support_air,pickEscortPlane);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortPlane',_value)]);
            };
            class escortHeli: Edit {
                property = QGVAR(jumpEscortHeli);
                displayName = "Rotary Escort Class";
                tooltip = "The rotary drone a helicopter's two escorts fly - only when the request's LZ security is YELLOW or RED (a JUMP REQUEST has none, so none). Empty: none. Not a helicopter class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QEGVAR(support_air,pickEscortHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortHeli',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One jump aircraft in TAC//MSG for HALO, HAHO and static-line jumps. Place one module per aircraft; many are allowed, on one side or several.",
                "",
                "A squad leader or an admin files a JUMP REQUEST to it by its callsign. It flies one run at a time.",
                "",
                "Virtual until tasked: no aircraft until a JUMP REQUEST is accepted. Then it is made in the air 2000 m up over this module and orbits here dark. The leader sends BOARD; the stick is put aboard, it climbs or descends to the jump altitude and flies the run, then flies back here and is removed.",
                "",
                "Side: the side of the units synced to the module; none synced, the players' side.",
                "",
                "A side with no module keeps one jump aircraft of its own, SKYTRAIN, flown from the Jumpmaster settings.",
                "",
                "Aircraft Class - Blank for the side's cargo aircraft",
                "Callsign - What TAC//MSG lists it as",
                "HALO / HAHO / Static Line Altitude (m) - Height of each kind of run",
                "Passes By Default - When the request leaves PASSES empty",
                "Exit By Default - When the request ticks no EXIT",
                "In The Aircraft - Seats, or standing in the bay",
                "Cooldown (sec) - Time after a run before the next",
                "Respawns - Aircraft that may be lost and replaced; 0 for none",
                "Respawn Delay (sec) - Time after a loss before a new aircraft can be tasked",
                "Fixed-Wing Escort Class - Two drones with a plane, always; blank for the side's UCAV",
                "Rotary Escort Class - Two drones with a helicopter for a YELLOW or RED LZ only"
            };
        };
    };
};
