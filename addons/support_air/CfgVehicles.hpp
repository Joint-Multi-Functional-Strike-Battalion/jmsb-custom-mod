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
    // same shape as the CAS drone module in addons/cas, so the four of these
    // read the same in Eden as the one already there. No module, no asset: an
    // air asset exists because a mission maker put it on the map, never
    // because a setting switched a kind of support on.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59). player_side on JMSB - Core is the
    // only place allegiance is typed; every module here belongs to the
    // players and reads their side from the slots.
    //
    // THE MODULE IS THE AIRBASE. Aircraft built from a class appear at the
    // module and go home to it; a module synced to an aircraft flies THAT
    // aircraft from where it stands and parks it back there. Where the
    // support goes is the requester's grid on TAC//SUPPORT, never a module
    // field.
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
            class sorties: Edit {
                property = QGVAR(casSorties);
                displayName = "Sorties";
                tooltip = "How many times this asset may be tasked before it is spent. A synced aircraft is also spent when it is lost. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "4";
                expression = QUOTE(_this setVariable [ARR_2('sorties',_value)]);
            };
            class altitude: Edit {
                property = QGVAR(casAltitude);
                displayName = "Altitude (m)";
                tooltip = "Height above the terrain the aircraft works at unless the requester picks one. A helicopter is held to its own ceiling for this - see the README.";
                typeName = "NUMBER";
                defaultValue = "600";
                expression = QUOTE(_this setVariable [ARR_2('altitude',_value)]);
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
                tooltip = "How long a SAD or a LOITER holds over the grid before the aircraft goes home by itself.";
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
            class spawnDelay: Edit {
                property = QGVAR(casSpawnDelay);
                displayName = "Response Delay (sec)";
                tooltip = "Time between the request being accepted and the aircraft leaving the module. A synced aircraft starts at once - it has to take off.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('spawnDelay',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(casCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after a sortie ends before this asset can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(casRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost a replacement is ready. A synced aircraft is rebuilt on its own stand with the crew it started with. -1: never - a lost aircraft is the asset lost for good.";
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
            class ingressDistance: Edit {
                property = QGVAR(casIngressDistance);
                displayName = "Ingress Distance (m)";
                tooltip = "An aircraft built from the class appears this far out on the requested INGRESS bearing and leaves the same distance out on the EGRESS, where it is removed - no airbase needed. Without an ingress it comes from the module's side. A synced aircraft takes off from its stand and flies the same legs.";
                typeName = "NUMBER";
                defaultValue = "6000";
                expression = QUOTE(_this setVariable [ARR_2('ingressDistance',_value)]);
            };
            class friendlyRange: Edit {
                property = QGVAR(casFriendlyRange);
                displayName = "Friendly Range (m)";
                tooltip = "A release is held while friendly troops are this close to the aim point, unless the requester set DANGER CLOSE. 0: never held.";
                typeName = "NUMBER";
                defaultValue = "100";
                expression = QUOTE(_this setVariable [ARR_2('friendlyRange',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable CAS aircraft on TAC//SUPPORT. Place one module per aircraft; many are allowed.",
                "",
                "Sync the module to an aircraft to fly that aircraft; otherwise the Aircraft Class is created at the module, which is its airbase.",
                "",
                "SAD holds over the grid and strikes what is painted or known inside the radius. LOITER orbits weapons-tight. ATTACK RUN makes the passes the requester sets, laser or smoke first.",
                "",
                "Aircraft Class - Crewed or drone aircraft; blank for the side's vanilla CAS jet",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Sorties - Taskings before it is spent; 0 for unlimited",
                "Altitude (m) - Working height above the terrain",
                "Run-In Distance (m) - How far past the target a run turns out",
                "Time On Station (sec) - How long a SAD or LOITER holds",
                "Terminal Search (m) - Laser/smoke search radius on a run; 0 for none",
                "Response Delay (sec) - Time from accepted request to launch",
                "Cooldown (sec) - Time after a sortie before it can be tasked again",
                "Respawn Delay (sec) - Time to replace a lost aircraft; -1 never",
                "Cooldown Starts - End of the sortie, or at the request",
                "Ingress Distance (m) - Where a class aircraft appears and leaves",
                "Friendly Range (m) - Releases held this close to friendlies unless DANGER CLOSE"
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
                tooltip = "Classname of the helicopter this asset flies. Ignored when the module is synced to a helicopter: that one flies instead. BLANK: the side's vanilla transport helicopter.";
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
            class airframes: Edit {
                property = QGVAR(transportAirframes);
                displayName = "Airframes Available";
                tooltip = "How many helicopters may be lost before the asset is spent. A synced helicopter is one airframe whatever this says. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('airframes',_value)]);
            };
            class height: Edit {
                property = QGVAR(transportHeight);
                displayName = "Flight Height (m)";
                tooltip = "Height above the terrain flown between points unless the requester picks one.";
                typeName = "NUMBER";
                defaultValue = "80";
                expression = QUOTE(_this setVariable [ARR_2('height',_value)]);
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
            class spawnDelay: Edit {
                property = QGVAR(transportSpawnDelay);
                displayName = "Response Delay (sec)";
                tooltip = "Time between the first request and the helicopter leaving the module. Later orders go to the helicopter already out.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('spawnDelay',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(transportCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the helicopter is home before it can be tasked again.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(transportRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost a replacement is ready. A synced aircraft is rebuilt on its own stand with the crew it started with. Airframes Available still caps how many may be lost. -1: never - a lost aircraft is the asset lost for good.";
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
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable transport helicopter on TAC//SUPPORT. Place one module per helicopter; many are allowed.",
                "",
                "Sync the module to a helicopter to fly that one; otherwise the class is created at the module, which is its base. The helicopter stays out between orders until it is sent home (RTB) or an EXTRACT brings it back.",
                "",
                "Helicopter Class - Blank for the side's vanilla transport",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Seats - Passenger seats offered; 0 for all",
                "Airframes Available - Losses before it is spent; 0 for unlimited",
                "Flight Height (m) - Height flown between points",
                "Extract Wait (sec) - How long an EXTRACT waits for the requester's group",
                "Task: ... - Which of PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP and SLINGLOAD it offers",
                "Paradrop Height (m) - Height a paradrop crosses the drop zone at",
                "Response Delay (sec) - Time from the first request to launch",
                "Cooldown (sec) - Time after it is home before it can be tasked again",
                "Respawn Delay (sec) - Time to replace a lost helicopter; -1 never",
                "Cooldown Starts - End of the sortie, or at the request"
            };
        };
    };

    class GVAR(moduleLogistics): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Logistics Drop";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleLogistics));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_support.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QGVAR(logisticsAircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft that flies the drop from the module. Sling needs a helicopter that can lift the crate. BLANK: the side's vanilla heavy helicopter.";
                typeName = "STRING";
                control = QGVAR(pickCargo);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(logisticsCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//SUPPORT and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'MULE'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class method: Combo {
                property = QGVAR(logisticsMethod);
                displayName = "Method";
                tooltip = "PARACHUTE: the crate leaves the aircraft over the grid under a cargo chute. SLING: a helicopter carries it on the hook and sets it down - a fixed-wing aircraft or a helicopter that cannot lift it falls back to the parachute.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('method',_value)]);
                class Values {
                    class chute { name = "Parachute"; value = 0; default = 1; };
                    class sling { name = "Sling (helicopter)"; value = 1; };
                };
            };
            class arsenalLists: Edit {
                property = QGVAR(logisticsArsenalLists);
                displayName = "PAC Arsenal Lists";
                tooltip = "Comma-separated arsenal list names whose classes fill the crate: 'magazines', 'itemsMedical', ... from the unit's common arsenal, or 'variant.list' from a named arsenal version. The mission's own Common_Arsenal lists of the same name are added. Separate LOADS with ';' (magazines; itemsMedical) and the requester picks one per drop as CONTENTS. Empty, or nothing found: the crate keeps its own contents.";
                typeName = "STRING";
                defaultValue = "'magazines'";
                expression = QUOTE(_this setVariable [ARR_2('arsenalLists',_value)]);
            };
            class magCount: Edit {
                property = QGVAR(logisticsMagCount);
                displayName = "Magazines Per Class";
                tooltip = "How many of each magazine on the lists go in the crate.";
                typeName = "NUMBER";
                defaultValue = "10";
                expression = QUOTE(_this setVariable [ARR_2('magCount',_value)]);
            };
            class itemCount: Edit {
                property = QGVAR(logisticsItemCount);
                displayName = "Other Gear Per Class";
                tooltip = "How many of each weapon, item or backpack on the lists go in the crate.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('itemCount',_value)]);
            };
            class crateClass: Edit {
                property = QGVAR(logisticsCrateClass);
                displayName = "Crate Class";
                tooltip = "Classname of the box that is dropped. When the arsenal lists give nothing it is dropped with its own contents.";
                typeName = "STRING";
                defaultValue = "'B_supplyCrate_F'";
                expression = QUOTE(_this setVariable [ARR_2('crateClass',_value)]);
            };
            class drops: Edit {
                property = QGVAR(logisticsDrops);
                displayName = "Drops";
                tooltip = "How many crates this asset delivers before it is spent. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('drops',_value)]);
            };
            class dropHeight: Edit {
                property = QGVAR(logisticsDropHeight);
                displayName = "Drop Height (m)";
                tooltip = "Height above the terrain a parachute drop is released from unless the requester picks one.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('dropHeight',_value)]);
            };
            class spawnDelay: Edit {
                property = QGVAR(logisticsSpawnDelay);
                displayName = "Response Delay (sec)";
                tooltip = "Time between the request being accepted and the aircraft leaving the module.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('spawnDelay',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(logisticsCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the aircraft is home before the next drop can be requested.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(logisticsRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost the asset can fly again. -1: never - a lost aircraft is the asset lost for good.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QGVAR(logisticsCooldownTrigger);
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
            class signal: Combo {
                property = QGVAR(logisticsSignal);
                displayName = "Crate Signal";
                tooltip = "What the crate sets off once it is on the ground, so the section can find it - unless the requester picks another.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('signal',_value)]);
                class Values {
                    class smoke { name = "Blue smoke"; value = 0; default = 1; };
                    class ir { name = "IR strobe"; value = 1; };
                    class chem { name = "Chemlight"; value = 2; };
                    class flare { name = "Flare"; value = 3; };
                    class none { name = "None"; value = 4; };
                };
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable supply drop on TAC//SUPPORT. An aircraft leaves the module, flies to the requester's grid, puts a crate down and goes home.",
                "",
                "The crate is filled from the unit's PAC arsenal lists named here, so it carries the unit's own gear.",
                "",
                "Aircraft Class - Blank for the side's vanilla heavy helicopter",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Method - Parachute, or sling for a helicopter",
                "PAC Arsenal Lists - List names that fill the crate; ';' between loads the requester picks from",
                "Magazines Per Class / Other Gear Per Class - Quantities",
                "Crate Class - The box; dropped with its own contents when the lists give nothing",
                "Drops - Crates before it is spent; 0 for unlimited",
                "Drop Height (m) - Parachute release height",
                "Response Delay (sec) - Time from accepted request to launch",
                "Cooldown (sec) - Time after the aircraft is home before the next drop",
                "Respawn Delay (sec) - Time before a lost aircraft is replaced; -1 never",
                "Cooldown Starts - End of the sortie, or at the request",
                "Crate Signal - Smoke, IR strobe, chemlight, flare or none on the landed crate"
            };
        };
    };

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
            class squads: Edit {
                property = QGVAR(qrfSquads);
                displayName = "Squads";
                tooltip = "How many squads this asset inserts before it is spent. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('squads',_value)]);
            };
            class staticAlt: Edit {
                property = QGVAR(qrfStaticAlt);
                displayName = "Static Line Height (m)";
                tooltip = "Height above the terrain of the static-line pass.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('staticAlt',_value)]);
            };
            class spawnDelay: Edit {
                property = QGVAR(qrfSpawnDelay);
                displayName = "Response Delay (sec)";
                tooltip = "Time between the request being accepted and the aircraft leaving the module.";
                typeName = "NUMBER";
                defaultValue = "90";
                expression = QUOTE(_this setVariable [ARR_2('spawnDelay',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(qrfCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the aircraft is home before the next squad can be requested.";
                typeName = "NUMBER";
                defaultValue = "600";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(qrfRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost the asset can fly again. -1: never - a lost aircraft is the asset lost for good.";
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
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable quick reaction force on TAC//SUPPORT: an AI squad of the players' side, flown from the module and inserted at the requester's grid.",
                "",
                "The requester picks the insertion among those the module allows: STATIC LINE or AIR ASSAULT. On the ground the squad defends the grid or joins the requester.",
                "",
                "Aircraft Class - Blank for the side's vanilla heavy helicopter",
                "Callsign - What TAC//SUPPORT and the radio call it",
                "Squad (CfgGroups) / Unit Classes - Who is inserted",
                "Insert: ... - Which insertion methods are offered",
                "On The Ground - Defend the grid or join the requester",
                "Defend Radius (m) - Area a defending squad holds",
                "Squads - Insertions before it is spent; 0 for unlimited",
                "Static Line Height (m) - Height of the static-line pass",
                "Response Delay (sec) - Time from accepted request to launch",
                "Cooldown (sec) - Time after the aircraft is home before the next squad",
                "Respawn Delay (sec) - Time before a lost aircraft is replaced; -1 never",
                "Cooldown Starts - End of the sortie, or at the request"
            };
        };
    };
};
