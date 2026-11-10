class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Combo;
            class Checkbox;
        };
        class ModuleDescription;
    };

    // ONE MODULE IS ONE ASSET ON TAC//SUPPORT, AND MANY MAY BE PLACED - the
    // same shape as the CAS drone module in addons/cas, so the three of these
    // read the same in Eden as the one already there. No module, no asset: an
    // air asset exists because a mission maker put it on the map, never
    // because a setting switched a kind of support on.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59). player_side on JMSB - Core is the
    // only place allegiance is typed; every module here belongs to the
    // players and reads their side from the slots.
    //
    // THE MODULE IS THE BASE (user, 2026-11-02: "all support aircraft needs to
    // be virtual till tasked, then they spawn in at alt over the support module
    // location"). An aircraft built from a class does not exist until a task
    // is accepted; then it is made in the air over the module at its height,
    // flies the task, comes back over the module and is removed there. A
    // module synced to an aircraft flies THAT aircraft from where it stands
    // and parks it back there. Where the support goes is the requester's grid,
    // never a module field. RESPAWNS (user, 2026-11-02: "make sure there is a
    // respawn count for each support, default no respawns") is how many more
    // airframes it has after one is lost.
    //
    // RETIRED 2026-11-02 with the virtual model, removed here: Response Delay
    // (spawnDelay - made at once when tasked), the CAS Ingress Distance
    // (ingressDistance - made over the module, not out on the bearing) and
    // Drone Escorts (escorts - a jet always takes them, a helicopter by LZ
    // security). A mission that set them still loads; the values are not read.
    class GVAR(moduleCAS): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - CAS";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleCAS));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_plane.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QGVAR(casAircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft this asset flies - a crewed jet or helicopter, or a drone. Ignored when the module is synced to an aircraft: that aircraft flies instead. BLANK: the side's vanilla CAS jet.";
                typeName = "STRING";
                control = QGVAR(pickCas);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(casCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//SUPPORT and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'HOG'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class runIn: Edit {
                property = QGVAR(casRunIn);
                displayName = "Run-In Distance (m)";
                tooltip = "How far past the target an attack run turns out before it comes round for the next pass.";
                typeName = "NUMBER";
                defaultValue = "3000";
                expression = QUOTE(_this setVariable [ARR_2('runIn',_value)]);
            };
            class stationTime: Edit {
                property = QGVAR(casStationTime);
                displayName = "Time On Station (sec)";
                tooltip = "How long a SAD, a LOITER or a REQUEST ON STATION holds before the aircraft returns to base, where it is removed until its next task.";
                typeName = "NUMBER";
                defaultValue = "600";
                expression = QUOTE(_this setVariable [ARR_2('stationTime',_value)]);
            };
            class searchRadius: Edit {
                property = QGVAR(casSearchRadius);
                displayName = "Terminal Search (m)";
                tooltip = "How far from the requested grid a laser spot or smoke is accepted as the real target on an attack run. 0: the grid is final.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('searchRadius',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(casCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after an aircraft is gone (home or lost) before this asset can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawns: Edit {
                property = QGVAR(casRespawns);
                displayName = "Respawns";
                tooltip = "Replacement aircraft after one is LOST (destroyed, crew dead, or disabled). The next task after the Respawn Delay gets a new one. Going home after a task uses none - the aircraft is removed over the module and made again for the next task. 0: none - after a loss the asset leaves the SUPPORT list.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(casRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost the asset can be tasked again, while Respawns are left. A synced aircraft is rebuilt on its own stand with the crew it started with.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QGVAR(casCooldownTrigger);
                displayName = "Cooldown Starts";
                tooltip = "END: the cooldown runs once the aircraft is home (or gone). START: it runs from the moment the request is accepted, while the sortie flies.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('cooldownTrigger',_value)]);
                class Values {
                    class atEnd { name = "End of the sortie"; value = 0; default = 1; };
                    class atStart { name = "At the request"; value = 1; };
                };
            };
            class friendlyRange: Edit {
                property = QGVAR(casFriendlyRange);
                displayName = "Friendly Range (m)";
                tooltip = "A release is held while friendly troops are this close to the aim point, unless the requester set DANGER CLOSE. 0: never held.";
                typeName = "NUMBER";
                defaultValue = "100";
                expression = QUOTE(_this setVariable [ARR_2('friendlyRange',_value)]);
            };
            // DRONE ESCORTS (user, 2026-11-02: "drone escorts is based on lz
            // security for helos and always for fix wings"), the same two
            // classes on every support aircraft module (FUNC(escortLaunch)).
            class escortPlane: Edit {
                property = QGVAR(casEscortPlane);
                displayName = "Fixed-Wing Escort Class";
                tooltip = "The fixed-wing drone a jet's two escorts fly - a jet always takes them, made beside it over the module and removed with it. They are what ALL ATTACK sends at the target area. Empty: the side's vanilla UCAV. Not a fixed-wing class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortPlane);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortPlane',_value)]);
            };
            class escortHeli: Edit {
                property = QGVAR(casEscortHeli);
                displayName = "Rotary Escort Class";
                tooltip = "The rotary drone a helicopter's two escorts fly - only when the request's LZ security is YELLOW or RED. Empty: none. Not a helicopter class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortHeli',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable CAS aircraft on TAC//SUPPORT. Place one module per aircraft; many are allowed.",
                "",
                "Sync the module to an aircraft to fly that aircraft from its stand. Otherwise the Aircraft Class is virtual until tasked: when a task is accepted it is made in the air over the module - a helicopter nap of the earth, a jet at 4000 m - flies the task, and is removed over the module when it comes home.",
                "",
                "SAD holds over the grid and strikes what is painted or known inside the radius. LOITER orbits weapons-tight. ATTACK RUN makes the passes the requester sets, laser or smoke first. A jet with its escorts up can be cleared ALL ATTACK: the drones attack the target area too.",
                "",
                "Flies tactically: lights only over its airfield; a helicopter nap of the earth; a fixed-wing attacks from 4000 m and holds 8 km off the map on station.",
                "",
                "Aircraft Class - Crewed or drone aircraft; blank for the side's vanilla CAS jet",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Run-In Distance (m) - How far past the target a run turns out",
                "Time On Station (sec) - How long a SAD, LOITER or REQUEST ON STATION holds",
                "Terminal Search (m) - Laser/smoke search radius on a run; 0 for none",
                "Cooldown (sec) - Time after an aircraft is gone before it can be tasked again",
                "Respawns - Replacements after a loss; 0 for none",
                "Respawn Delay (sec) - Time after a loss before it can be tasked again",
                "Cooldown Starts - End of the sortie, or at the request",
                "Friendly Range (m) - Releases held this close to friendlies unless DANGER CLOSE",
                "Fixed-Wing Escort Class - A jet's two drones, always; empty for the side's UCAV",
                "Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none"
            };
        };
    };

    class GVAR(moduleTransport): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Transport";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleTransport));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_air.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QGVAR(transportAircraftClass);
                displayName = "Helicopter Class";
                tooltip = "Classname of the helicopter or VTOL this asset flies. A VTOL takes off, hovers and lands as a helicopter and flies as a plane beyond 1 km of its point. Ignored when the module is synced to an aircraft: that one flies instead. BLANK: the side's vanilla transport helicopter.";
                typeName = "STRING";
                control = QGVAR(pickHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(transportCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//SUPPORT and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'RAVEN'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class seats: Edit {
                property = QGVAR(transportSeats);
                displayName = "Seats";
                tooltip = "Passenger seats offered; the rest of the cargo seats are locked. 0: every cargo seat the helicopter has.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('seats',_value)]);
            };
            class waitTime: Edit {
                property = QGVAR(transportWaitTime);
                displayName = "Extract Wait (sec)";
                tooltip = "How long an EXTRACT waits on the ground for the requester's group before it leaves with whoever is aboard, unless the requester picks a wait.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('waitTime',_value)]);
            };
            class allowPickup: Checkbox {
                property = QGVAR(transportAllowPickup);
                displayName = "Task: Pickup";
                tooltip = "PICKUP - land at the grid (or on the requester) engine running and wait for the next order.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowPickup',_value)]);
            };
            class allowLand: Checkbox {
                property = QGVAR(transportAllowLand);
                displayName = "Task: Land";
                tooltip = "LAND - land at the grid, put the passengers out and wait engine running.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowLand',_value)]);
            };
            class allowLandOff: Checkbox {
                property = QGVAR(transportAllowLandOff);
                displayName = "Task: Land Engine Off";
                tooltip = "LAND ENG OFF - land at the grid and shut down.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowLandOff',_value)]);
            };
            class allowMove: Checkbox {
                property = QGVAR(transportAllowMove);
                displayName = "Task: Hover";
                tooltip = "HOVER - fly to the grid and hold a hover there.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowMove',_value)]);
            };
            class allowExtract: Checkbox {
                property = QGVAR(transportAllowExtract);
                displayName = "Task: Extract";
                tooltip = "EXTRACT - land at the grid (or on the requester), wait for his group, fly them to the module and land.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowExtract',_value)]);
            };
            class allowLift: Checkbox {
                property = QGVAR(transportAllowLift);
                displayName = "Task: Pickup > LZ";
                tooltip = "PICKUP > LZ - land at the pickup (or on the requester), wait for his group, fly it to the LZ and put it out.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowLift',_value)]);
            };
            class allowOrbit: Checkbox {
                property = QGVAR(transportAllowOrbit);
                displayName = "Task: Loiter";
                tooltip = "LOITER - orbit the grid at the requested radius until the next order.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowOrbit',_value)]);
            };
            class allowFastrope: Checkbox {
                property = QGVAR(transportAllowFastrope);
                displayName = "Task: Fastrope";
                tooltip = "FASTROPE - hover over the grid with ropes out. Offered only where ACE fast-roping is loaded and the helicopter can take FRIES.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowFastrope',_value)]);
            };
            class allowHelocast: Checkbox {
                property = QGVAR(transportAllowHelocast);
                displayName = "Task: Helocast";
                tooltip = "HELOCAST - come down to the water at the grid and drift while the cabin goes out. The grid must be water.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowHelocast',_value)]);
            };
            class allowParadrop: Checkbox {
                property = QGVAR(transportAllowParadrop);
                displayName = "Task: Paradrop";
                tooltip = "PARADROP - cross the drop zone at the jump height and put the whole cabin out on static lines, then return to base.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowParadrop',_value)]);
            };
            class allowSlingload: Checkbox {
                property = QGVAR(transportAllowSlingload);
                displayName = "Task: Slingload";
                tooltip = "SLINGLOAD - hook the nearest liftable object at the load point, carry it to the set-down point and lower it. Offered only for a helicopter with a cargo hook.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowSlingload',_value)]);
            };
            class jumpHeight: Edit {
                property = QGVAR(transportJumpHeight);
                displayName = "Paradrop Height (m)";
                tooltip = "Height above the terrain a PARADROP crosses the drop zone at unless the requester picks one.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('jumpHeight',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(transportCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the helicopter is home (or lost) before it can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawns: Edit {
                property = QGVAR(transportRespawns);
                displayName = "Respawns";
                tooltip = "Replacement helicopters after one is LOST (destroyed, crew dead, or disabled). The next task after the Respawn Delay gets a new one. Going home after a lift uses none - it lands at the module, is removed, and is made again for the next task. 0: none - after a loss the asset leaves the SUPPORT list.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(transportRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its helicopter is lost the asset can be tasked again, while Respawns are left. A synced helicopter is rebuilt on its own stand with the crew it started with.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QGVAR(transportCooldownTrigger);
                displayName = "Cooldown Starts";
                tooltip = "END: the cooldown runs once the aircraft is home (or gone). START: it runs from the moment the request is accepted, while the sortie flies.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('cooldownTrigger',_value)]);
                class Values {
                    class atEnd { name = "End of the sortie"; value = 0; default = 1; };
                    class atStart { name = "At the request"; value = 1; };
                };
            };
            // DRONE ESCORTS (user, 2026-11-02: "based on lz security for
            // helos"). A helicopter only, so the rotary class only.
            class escortHeli: Edit {
                property = QGVAR(transportEscortHeli);
                displayName = "Rotary Escort Class";
                tooltip = "The rotary drone of the helicopter's two escorts - only when the request's LZ security is YELLOW or RED (GREEN, or no security line: none). Made beside it over the module, nap of the earth and dark like it, removed with it. Empty: none. Not a helicopter class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortHeli',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable transport helicopter on TAC//SUPPORT. Place one module per helicopter; many are allowed.",
                "",
                "Sync the module to a helicopter to fly that one from its stand. Otherwise the class is virtual until tasked: when a request is accepted it is made in the air over the module, nap of the earth, and flies the lift. After it it flies the egress, RTBs to the module, lands, unloads and is removed - ready for the next request.",
                "",
                "Flies tactically: nap of the earth (higher with a sling load), lights only over its base.",
                "",
                "Helicopter Class - Blank for the side's vanilla transport",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Seats - Passenger seats offered; 0 for all",
                "Extract Wait (sec) - How long an EXTRACT waits for the requester's group",
                "Task: ... - Which of PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP and SLINGLOAD it offers",
                "Paradrop Height (m) - Height a paradrop crosses the drop zone at",
                "Cooldown (sec) - Time after it is home before it can be tasked again",
                "Respawns - Replacements after a loss; 0 for none",
                "Respawn Delay (sec) - Time after a loss before it can be tasked again",
                "Cooldown Starts - End of the sortie, or at the request",
                "Rotary Escort Class - Two drones on a YELLOW or RED LZ; empty for none"
            };
        };
    };

    // JMSB - LOGISTICS DROP MOVED to addons/support_logistics (user,
    // 2026-11-01): JMSB - Logistics there, with a catalog, airdrop and sling.
    // Its old class, jmfsb_support_air_moduleLogistics, is defined there,
    // hidden, so the missions that placed it still load.

    class GVAR(moduleQRF): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - QRF Insertion";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleQRF));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_inf.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QGVAR(qrfAircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft that carries the squad. AIR ASSAULT needs a helicopter and is not offered for anything else. BLANK: the side's vanilla heavy helicopter.";
                typeName = "STRING";
                control = QGVAR(pickCargo);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(qrfCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//SUPPORT and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'REACH'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class groupClass: Edit {
                property = QGVAR(qrfGroupClass);
                displayName = "Squad (CfgGroups)";
                tooltip = "The squad as a CfgGroups path: side/faction/category/group, e.g. West/BLU_F/Infantry/BIS_InfSquad. BLANK: the side's vanilla rifle squad. Ignored when Unit Classes is set.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('groupClass',_value)]);
            };
            class unitClasses: Edit {
                property = QGVAR(qrfUnitClasses);
                displayName = "Unit Classes";
                tooltip = "Comma-separated soldier classnames, leader first. When set, this is the squad and Squad (CfgGroups) is ignored.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('unitClasses',_value)]);
            };
            class allowStatic: Checkbox {
                property = QGVAR(qrfAllowStatic);
                displayName = "Insert: Static Line";
                tooltip = "STATIC LINE - a low slow pass over the grid, chutes open on exit.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowStatic',_value)]);
            };
            class allowAssault: Checkbox {
                property = QGVAR(qrfAllowAssault);
                displayName = "Insert: Air Assault";
                tooltip = "AIR ASSAULT - a helicopter lands the squad at the grid, or fast-ropes it in where ACE fast-roping is loaded and the airframe has FRIES, then leaves.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowAssault',_value)]);
            };
            class onLanding: Combo {
                property = QGVAR(qrfOnLanding);
                displayName = "On The Ground";
                tooltip = "DEFEND: the squad holds the grid. JOIN: the squad joins the requester's group and takes his orders.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('onLanding',_value)]);
                class Values {
                    class defend { name = "Defend the grid"; value = 0; default = 1; };
                    class join { name = "Join the requester"; value = 1; };
                };
            };
            class defendRadius: Edit {
                property = QGVAR(qrfDefendRadius);
                displayName = "Defend Radius (m)";
                tooltip = "How far around the grid a defending squad takes up positions.";
                typeName = "NUMBER";
                defaultValue = "100";
                expression = QUOTE(_this setVariable [ARR_2('defendRadius',_value)]);
            };
            class staticAlt: Edit {
                property = QGVAR(qrfStaticAlt);
                displayName = "Static Line Height (m)";
                tooltip = "Height above the terrain of the static-line pass.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('staticAlt',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(qrfCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the aircraft is home before the next squad can be requested.";
                typeName = "NUMBER";
                defaultValue = "600";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawns: Edit {
                property = QGVAR(qrfRespawns);
                displayName = "Respawns";
                tooltip = "Replacement aircraft after one is LOST (destroyed, crew dead, or disabled). The next request after the Respawn Delay gets a new one. Every request is a fresh aircraft and squad made over the module; going home after an insertion uses none. 0: none - after a loss the asset leaves the SUPPORT list.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(qrfRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost the asset can be tasked again, while Respawns are left.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QGVAR(qrfCooldownTrigger);
                displayName = "Cooldown Starts";
                tooltip = "END: the cooldown runs once the aircraft is home (or gone). START: it runs from the moment the request is accepted, while the sortie flies.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('cooldownTrigger',_value)]);
                class Values {
                    class atEnd { name = "End of the sortie"; value = 0; default = 1; };
                    class atStart { name = "At the request"; value = 1; };
                };
            };
            // DRONE ESCORTS (user, 2026-11-02: "based on lz security for helos
            // and always for fix wings").
            class escortPlane: Edit {
                property = QGVAR(qrfEscortPlane);
                displayName = "Fixed-Wing Escort Class";
                tooltip = "The fixed-wing drone of a plane's two escorts - a plane always takes them, made beside it over the module and removed with it. Empty: the side's vanilla UCAV. Not a fixed-wing class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortPlane);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortPlane',_value)]);
            };
            class escortHeli: Edit {
                property = QGVAR(qrfEscortHeli);
                displayName = "Rotary Escort Class";
                tooltip = "The rotary drone of a helicopter's two escorts - only when the request's LZ security is YELLOW or RED (a QRF card has none: no escort). Empty: none. Not a helicopter class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortHeli',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable quick reaction force on TAC//SUPPORT: an AI squad of the players' side, flown from the module and inserted at the requester's grid. Virtual until tasked: at the request the aircraft is made in the air over the module with the squad aboard. After the insertion it RTBs to the module and is removed - ready for the next request.",
                "",
                "The requester picks the insertion among those the module allows: STATIC LINE or AIR ASSAULT. On the ground the squad defends the grid or joins the requester.",
                "",
                "Aircraft Class - Blank for the side's vanilla heavy helicopter",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Squad (CfgGroups) / Unit Classes - Who is inserted",
                "Insert: ... - Which insertion methods are offered",
                "On The Ground - Defend the grid or join the requester",
                "Defend Radius (m) - Area a defending squad holds",
                "Static Line Height (m) - Height of the static-line pass",
                "Cooldown (sec) - Time after the aircraft is home before the next squad",
                "Respawns - Replacements after a loss; 0 for none",
                "Respawn Delay (sec) - Time after a loss before it can be tasked again",
                "Cooldown Starts - End of the sortie, or at the request",
                "Fixed-Wing Escort Class - A plane's two drones, always; empty for the side's UCAV",
                "Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none"
            };
        };
    };
};
