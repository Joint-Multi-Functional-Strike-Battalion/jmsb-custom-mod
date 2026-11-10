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

    // ONE MODULE IS ONE LOGISTICS ASSET, ONE BOX IN TAC//MSG, AND MANY MAY BE
    // PLACED - shaped like support_air's modules, which this one came out of
    // (user, 2026-11-01: "add a logistic to support based on simplexs").
    // Simplex Support Services is a behaviour reference only (GPLv2): its
    // airdrop and slingload, its reference area and its item cooldown, done
    // the way this mod does things.
    //
    // NO SIDE ATTRIBUTE, BY RULE (D59): the players' side comes from the slots.
    //
    // THE MODULE IS THE AIRBASE (user, 2026-11-02: "all support aircraft
    // needs to be virtual till tasked, then they spawn in at alt over the
    // support module location"): no aircraft until a delivery is accepted,
    // then it is made in the air over the module and removed over it when it
    // is home. Where the order goes is the card's point, never a module field.
    //
    // WHAT CAN BE ORDERED is the catalog: the objects placed inside a synced
    // JMSB - Logistics Catalog area (or synced to that module), each with its
    // editor inventory, and one supply crate per PAC load named here.
    class GVAR(module): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Logistics";
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
                property = QGVAR(aircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft that delivers. SLING needs a helicopter with a cargo hook; an airdrop takes any aircraft. BLANK: the side's vanilla heavy helicopter.";
                typeName = "STRING";
                control = QGVAR(pickCargo);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QGVAR(callsign);
                displayName = "Callsign";
                tooltip = "What TAC//MSG and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'MULE'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class allowAirdrop: Checkbox {
                property = QGVAR(allowAirdrop);
                displayName = "Method: Airdrop";
                tooltip = "AIRDROP - the aircraft flies over the delivery point and puts the order out under chutes, one item after another.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowAirdrop',_value)]);
            };
            class allowSling: Checkbox {
                property = QGVAR(allowSling);
                displayName = "Method: Sling Load";
                tooltip = "SLING LOAD - each item comes in on a helicopter's hook and is set down on the point. Offered only for a helicopter with a cargo hook, and only for items it can lift.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('allowSling',_value)]);
            };
            class capacity: Edit {
                property = QGVAR(capacity);
                displayName = "Capacity";
                tooltip = "How many items one order may hold, whatever they are.";
                typeName = "NUMBER";
                defaultValue = "4";
                expression = QUOTE(_this setVariable [ARR_2('capacity',_value)]);
            };
            class fulfillment: Combo {
                property = QGVAR(fulfillment);
                displayName = "Sling Fulfillment";
                tooltip = "A hook carries one load. ONE HELICOPTER: a sling order is one item. ONE PER ITEM: a helicopter flies for each item ordered, up to the Capacity, side by side.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('fulfillment',_value)]);
                class Values {
                    class one { name = "One helicopter"; value = 0; };
                    class each { name = "One helicopter per item"; value = 1; default = 1; };
                };
            };
            class dropHeight: Edit {
                property = QGVAR(dropHeight);
                displayName = "Drop Height (m)";
                tooltip = "Height above the terrain an airdrop crosses the point at, unless the requester picks one. At least 100.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('dropHeight',_value)]);
            };
            class openHeight: Edit {
                property = QGVAR(openHeight);
                displayName = "Chute Opens At (m)";
                tooltip = "Height above the terrain an airdropped vehicle or crate opens its chute at, falling free until then. -1: at once, on leaving the aircraft. Objects the game does not simulate always open at once.";
                typeName = "NUMBER";
                defaultValue = -1;
                expression = QUOTE(_this setVariable [ARR_2('openHeight',_value)]);
            };
            class unloadHeight: Edit {
                property = QGVAR(unloadHeight);
                displayName = "Unload Height (m)";
                tooltip = "How high over the point a sling load hangs in the hover before it is lowered to the ground and the hook let go - clearance of what stands round the point. At least 5.";
                typeName = "NUMBER";
                defaultValue = "12";
                expression = QUOTE(_this setVariable [ARR_2('unloadHeight',_value)]);
            };
            // SPAWN DISTANCE AND RESPONSE DELAY ARE RETIRED (user, 2026-11-02:
            // "all support aircraft needs to be virtual till tasked, then they
            // spawn in at alt over the support module location"): the aircraft
            // is made over the module the moment the request is accepted. A
            // mission that set them still loads; the values are not read.
            class cooldown: Edit {
                property = QGVAR(cooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after a delivery before the next one can be requested.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class itemCooldown: Edit {
                property = QGVAR(itemCooldown);
                displayName = "Item Cooldown (sec)";
                tooltip = "Added to the cooldown for every item delivered (or, when the cooldown starts at the request, every item ordered).";
                typeName = "NUMBER";
                defaultValue = "30";
                expression = QUOTE(_this setVariable [ARR_2('itemCooldown',_value)]);
            };
            // RESPAWNS (user, 2026-11-02: "make sure there is a respawn count
            // for each support, default no respawns"; and the same day,
            // virtual until tasked): only an aircraft LOST uses one - a
            // delivery that goes home is despawned over the module and costs
            // nothing.
            class respawns: Edit {
                property = QGVAR(respawns);
                displayName = "Respawns";
                tooltip = "Replacement aircraft for ones LOST (destroyed, crew dead, or written off). The aircraft is only made when a delivery is tasked, over the module, and is removed there when it is home - going home uses no respawn. A loss uses one; the next delivery can fly after the Respawn Delay. A loss with none left: the asset leaves the SUPPORT list and answers UNABLE - NO AIRFRAME. -1: unlimited.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('respawns',_value)]);
            };
            class respawnDelay: Edit {
                property = QGVAR(respawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after an aircraft is lost its replacement can fly, while Respawns are left.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QGVAR(cooldownTrigger);
                displayName = "Cooldown Starts";
                tooltip = "END: the cooldown runs once the last aircraft is gone. START: it runs from the moment the request is accepted.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('cooldownTrigger',_value)]);
                class Values {
                    class atEnd { name = "End of the delivery"; value = 0; default = 1; };
                    class atStart { name = "At the request"; value = 1; };
                };
            };
            class crateClass: Edit {
                property = QGVAR(crateClass);
                displayName = "Crate Class";
                tooltip = "Classname of the box a PAC load is packed in. When its arsenal lists give nothing it is sent with its own contents.";
                typeName = "STRING";
                defaultValue = "'B_supplyCrate_F'";
                expression = QUOTE(_this setVariable [ARR_2('crateClass',_value)]);
            };
            class arsenalLists: Edit {
                property = QGVAR(arsenalLists);
                displayName = "PAC Arsenal Lists";
                tooltip = "Each LOAD is one crate in the catalog: comma-separated arsenal list names ('magazines', 'itemsMedical', ... from the unit's common arsenal, or 'variant.list' from a named arsenal version), the mission's own Common_Arsenal lists of the same name added. Separate loads with ';' (magazines; itemsMedical). Empty: no PAC crates.";
                typeName = "STRING";
                defaultValue = "'magazines'";
                expression = QUOTE(_this setVariable [ARR_2('arsenalLists',_value)]);
            };
            class magCount: Edit {
                property = QGVAR(magCount);
                displayName = "Magazines Per Class";
                tooltip = "How many of each magazine on a PAC load go in its crate.";
                typeName = "NUMBER";
                defaultValue = "10";
                expression = QUOTE(_this setVariable [ARR_2('magCount',_value)]);
            };
            class itemCount: Edit {
                property = QGVAR(itemCount);
                displayName = "Other Gear Per Class";
                tooltip = "How many of each weapon, item or backpack on a PAC load go in its crate.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('itemCount',_value)]);
            };
            class signal: Combo {
                property = QGVAR(signal);
                displayName = "Marking";
                tooltip = "What each delivered item sets off once it is on the ground, so the section can find it - unless the requester picks another.";
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
            // DRONE ESCORTS (user, 2026-11-02: "drone escorts is based on lz
            // security for helos and always for fix wings"), as support_air's
            // modules have them (EFUNC(support_air,escortLaunch)). The Drone
            // Escorts on/off is retired: a mission that set it still loads,
            // the value is not read.
            class escortPlane: Edit {
                property = QGVAR(escortPlane);
                displayName = "Fixed-Wing Escort Class";
                tooltip = "A plane always takes two drone wingmen: this fixed-wing drone. They are made with it over the module, fly dark with it, engage what threatens it and what is round the drop, put out flares when a missile comes, and are removed with it. Empty: the side's vanilla UCAV. Not a fixed-wing class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortPlane);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortPlane',_value)]);
            };
            class escortHeli: Edit {
                property = QGVAR(escortHeli);
                displayName = "Rotary Escort Class";
                tooltip = "A helicopter takes two drone wingmen of this rotary class only when the request's LZ security is YELLOW or RED (GREEN, or no security on the card: none). Empty: none. Not a helicopter class in this mission: no escort, and one RPT warning.";
                typeName = "STRING";
                control = QGVAR(pickEscortHeli);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('escortHeli',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One taskable logistics asset: a TAC//MSG resupply message to its box orders items from the catalog by name, to the card's delivery point, by AIRDROP or SLING LOAD.",
                "",
                "The catalog: everything placed inside a synced JMSB - Logistics Catalog area (or synced to that module), with its editor inventory, plus one supply crate per PAC load named here.",
                "",
                "Virtual until tasked: no aircraft exists until a delivery is accepted; then it is made in the air over the module at its flight height, flies the delivery, comes back and is removed over the module.",
                "",
                "Flies tactically: lights only over the module, helicopters nap of the earth (higher with a sling load), planes high until the drop.",
                "",
                "Aircraft Class - Blank for the side's vanilla heavy helicopter",
                "Callsign - What TAC//MSG and the radio call it",
                "Method: ... - Airdrop and/or sling load",
                "Capacity - Items one order may hold",
                "Sling Fulfillment - One helicopter, or one per item",
                "Drop Height / Chute Opens At (m) - The airdrop pass and the chutes",
                "Unload Height (m) - The hover over the point before a sling load is lowered to the ground",
                "Cooldown / Item Cooldown (sec) - Time before the next delivery, plus per item",
                "Respawns - Replacements for aircraft lost; 0 none, -1 unlimited",
                "Respawn Delay (sec) - Time after a loss before the next delivery can fly",
                "Cooldown Starts - End of the delivery, or at the request",
                "Crate Class / PAC Arsenal Lists / Per Class - The PAC crates",
                "Marking - Smoke, IR strobe, chemlight, flare or none on what lands",
                "Fixed-Wing Escort Class - Two drone wingmen with a plane, always; empty for the side's vanilla UCAV",
                "Rotary Escort Class - Two drone wingmen with a helicopter when the LZ security is YELLOW or RED; empty for none"
            };
        };
    };

    // THE REFERENCE AREA (Simplex's idea, behaviour only). Size it over a
    // corner of the map, put in it - or sync to it - what may be ordered:
    // vehicles, crates and other objects, with their editor inventory and
    // paint. Sync it to one or more JMSB - Logistics modules. The server reads
    // it once at the start (FUNC(catalogRead)) and, by default, removes the
    // objects it read, so the area is a shelf, not a car park.
    class GVAR(moduleCatalog): Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "JMSB - Logistics Catalog";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleCatalog));
        functionPriority = 0;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;
        canSetAreaShape = 1;
        icon = "\a3\ui_f\data\map\markers\nato\b_unknown.paa";

        class AttributeValues {
            size3[] = {25, 25, -1};
            isRectangle = 1;
        };

        class Attributes: AttributesBase {
            class removeObjects: Checkbox {
                property = QGVAR(catalogRemove);
                displayName = "Remove The Objects";
                tooltip = "Once read at the start, the objects in the area (and synced to it) are removed - they were only the catalog. Untick to leave them standing.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('removeObjects',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "What a JMSB - Logistics module can deliver. Sync this module to one or more of them.",
                "",
                "Every vehicle, crate or other object inside the area, or synced to this module, is one item of the catalog - its editor inventory and paint go with it. Units and crewed vehicles are not items; identical objects are one item.",
                "",
                "Remove The Objects - Clear the area once it is read"
            };
        };
    };

    // THE OLD JMSB - LOGISTICS DROP (support_air until 2026-11-01). Its class
    // name, attribute properties and variable names are kept exactly, so a
    // mission that placed it loads and keeps its settings; it is hidden from
    // the editor list (scope 1) and FUNC(moduleLegacy) reads it into the
    // module above - one asset of this addon, kind "logi". Class names are
    // the one place the prefix is written out (CODING_GUIDELINES.md).
    class jmfsb_support_air_moduleLogistics: Module_F {
        scope = 1;
        scopeCurator = 0;
        displayName = "JMSB - Logistics Drop (old)";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleLegacy));
        functionPriority = 1;
        isGlobal = 2;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\b_support.paa";

        class Attributes: AttributesBase {
            class aircraftClass: Edit {
                property = QEGVAR(support_air,logisticsAircraftClass);
                displayName = "Aircraft Class";
                tooltip = "Classname of the aircraft that flies the drop from the module. Sling needs a helicopter that can lift the crate. BLANK: the side's vanilla heavy helicopter.";
                typeName = "STRING";
                control = QGVAR(pickCargo);
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('aircraftClass',_value)]);
            };
            class callsign: Edit {
                property = QEGVAR(support_air,logisticsCallsign);
                displayName = "Callsign";
                tooltip = "What TAC//MSG and the radio call it. Give each module its own.";
                typeName = "STRING";
                defaultValue = "'MULE'";
                expression = QUOTE(_this setVariable [ARR_2('callsign',_value)]);
            };
            class method: Combo {
                property = QEGVAR(support_air,logisticsMethod);
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
                property = QEGVAR(support_air,logisticsArsenalLists);
                displayName = "PAC Arsenal Lists";
                tooltip = "Comma-separated arsenal list names whose classes fill the crate. Separate LOADS with ';' - each load is one crate the requester can order.";
                typeName = "STRING";
                defaultValue = "'magazines'";
                expression = QUOTE(_this setVariable [ARR_2('arsenalLists',_value)]);
            };
            class magCount: Edit {
                property = QEGVAR(support_air,logisticsMagCount);
                displayName = "Magazines Per Class";
                tooltip = "How many of each magazine on the lists go in the crate.";
                typeName = "NUMBER";
                defaultValue = "10";
                expression = QUOTE(_this setVariable [ARR_2('magCount',_value)]);
            };
            class itemCount: Edit {
                property = QEGVAR(support_air,logisticsItemCount);
                displayName = "Other Gear Per Class";
                tooltip = "How many of each weapon, item or backpack on the lists go in the crate.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('itemCount',_value)]);
            };
            class crateClass: Edit {
                property = QEGVAR(support_air,logisticsCrateClass);
                displayName = "Crate Class";
                tooltip = "Classname of the box that is dropped. When the arsenal lists give nothing it is dropped with its own contents.";
                typeName = "STRING";
                defaultValue = "'B_supplyCrate_F'";
                expression = QUOTE(_this setVariable [ARR_2('crateClass',_value)]);
            };
            class drops: Edit {
                property = QEGVAR(support_air,logisticsDrops);
                displayName = "Drops";
                tooltip = "Read as Respawns, one fewer (2026-11-02) - replacements for aircraft lost; a delivery that goes home costs nothing. 0: unlimited.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('drops',_value)]);
            };
            class dropHeight: Edit {
                property = QEGVAR(support_air,logisticsDropHeight);
                displayName = "Drop Height (m)";
                tooltip = "Height above the terrain a parachute drop is released from unless the requester picks one.";
                typeName = "NUMBER";
                defaultValue = "250";
                expression = QUOTE(_this setVariable [ARR_2('dropHeight',_value)]);
            };
            // Response Delay retired (user, 2026-11-02: virtual until tasked):
            // a mission that set it still loads, the value is not read.
            class cooldown: Edit {
                property = QEGVAR(support_air,logisticsCooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Time after the aircraft is home before the next drop can be requested.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
            class respawnDelay: Edit {
                property = QEGVAR(support_air,logisticsRespawnDelay);
                displayName = "Respawn Delay (sec)";
                tooltip = "How long after its aircraft is lost the next one can fly, while drops are left.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('respawnDelay',_value)]);
            };
            class cooldownTrigger: Combo {
                property = QEGVAR(support_air,logisticsCooldownTrigger);
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
                property = QEGVAR(support_air,logisticsSignal);
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
                "Replaced by JMSB - Logistics (2026-11-01). Kept so missions that placed it still load: it becomes a JMSB - Logistics asset with a capacity of one crate, flown from the module.",
                "",
                "Place JMSB - Logistics in new missions."
            };
        };
    };
};
