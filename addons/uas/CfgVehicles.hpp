class CfgVehicles {
    // The airframe picker is jmfsb_ClassPick_Uav_Single in jmfsb_main's
    // CfgEdenDrone.hpp, a Cfg3DEN control. An attribute NAMES it with
    // `control = ...` (see swarmClass below) - it must never be declared or
    // inherited in here. A forward declaration of it inside CfgVehicles is an
    // empty vehicle class of that name, and the 3DEN item preload then asks it
    // for scope, side, model and two hundred other things it does not have.
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Checkbox;
            class Combo;
            };
        class ModuleDescription;
    };

    // ONE MODULE, ONE PATROL ZONE, AND IT IS AN AREA. In jmfsb this was a single
    // switch: place it and every ALiVE commander flew drones over its own
    // objectives. There are no commanders and no objective lists, so the WHERE
    // had nothing to read - and the replacement is to draw it.
    //
    // Resize it in Eden or Zeus and the area is the ground patrolled. Place
    // several for several places, one per side for a side that needs one. The
    // first one armed starts the system.
    //
    // NOBODY NEAR, NOTHING FLYING is unchanged, and is why this is worth having:
    // a zone with no player within 3.2 km is not patrolled, and patrols whose
    // audience has left are retired. An empty map costs nothing.
    class jmfsb_moduleDronePatrol: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Drone Patrol";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleDronePatrol));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;
        icon = "\a3\ui_f\data\map\markers\nato\o_air.paa";

        class Attributes: AttributesBase {
            class droneCount: Edit {
                property = QGVAR(droneCount);
                displayName = "Drones";
                tooltip = "How many airframes this patrol keeps up. They are replaced as they are lost. 0 is a module placed and switched off rather than deleted.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('droneCount',_value)]);
            };
            class droneClass: Edit {
                property = QGVAR(droneClass);
                displayName = "Drone Class";
                tooltip = "The airframe, e.g. O_UAV_01_F. Empty flies a UAV belonging to the enemy side, which is the ordinary case. A class that does not exist falls back the same way and says so in the RPT.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('droneClass',_value)]);
            };

            // ---- artillery on detection --------------------------------------
            class artyOnDetect: Checkbox {
                property = QGVAR(artyOnDetect);
                displayName = "Artillery On Detect";
                tooltip = "A drone from this patrol that actually SEES somebody calls artillery on where it saw them. Off: it reports down the reaction path and nothing else, which is the default because this turns overflight from a thing you hide from into a thing that kills you.";
                defaultValue = 0;
                expression = QUOTE(_this setVariable [ARR_2('artyOnDetect',_value)]);
            };
            class artyRounds: Edit {
                property = QGVAR(artyRounds);
                displayName = "Rounds";
                tooltip = "Shells per mission.";
                typeName = "NUMBER";
                defaultValue = "6";
                expression = QUOTE(_this setVariable [ARR_2('artyRounds',_value)]);
            };
            class artyScatter: Edit {
                property = QGVAR(artyScatter);
                displayName = "Scatter (m)";
                tooltip = "How wide the fall of shot is around where the contact WAS seen, not where it is when the shells land. Moving is the counter.";
                typeName = "NUMBER";
                defaultValue = "100";
                expression = QUOTE(_this setVariable [ARR_2('artyScatter',_value)]);
            };
            class artyCooldown: Edit {
                property = QGVAR(artyCooldown);
                displayName = "Cooldown (s)";
                tooltip = "Minimum gap between two missions from THIS patrol. Without it a module flying four airframes over one section is four fire missions.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('artyCooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One patrol. Resize it - the area is the ground the drones fly over.",
                "",
                "Side - whoever is hostile to the players, worked out from the mission's side relations",
                "Drones - how many airframes this patrol keeps up",
                "Drone Class - empty flies the enemy side's own",
                "",
                "Artillery On Detect - a drone that sees somebody shells where it saw them",
                "Rounds / Scatter (m) / Cooldown (s) - the size of that mission and its gap",
                "",
                "A module never resized is one 800 m orbit. Nobody within 3.2 km, nothing flies.",
            };
        };
    };

    // ---- THE IED PELICAN - a cargo quad with a charge where the crate was ----
    //
    // THE BASE GAME'S AL-6 PELICAN, INDEPENDENT, WITH NOTHING ADDED IN CONFIG:
    // the charge is FUNC(iedDrone), armed by the Extended_Init handler in
    // CfgEventHandlers.hpp, and Drongo's Drone Tweaks flies it because
    // XEH_postInit registers it as an FPV. It is IND and low tier - the
    // insurgents' and the Syndikat's answer to everything - and the factions
    // that field it wrap it with their own class (gen_us_factions EXTRA_UNITS),
    // which is why it declares no faction of its own.
    //
    // THE BAG IS WHAT MAKES IT AN AI WEAPON. DDT hands a drone to a man by
    // reading the backpack's assembleInfo, so the operator carries this and
    // not the base game's Pelican bag - assembling that would give him a
    // cargo quad.
    class I_UAV_06_F;
    class I_UAV_06_backpack_F;

    class GVAR(UAV_06_IED_I): I_UAV_06_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AL-6 Pelican (IED)";
        side = 2;
    };
    class GVAR(UAV_06_IED_backpack_I): I_UAV_06_backpack_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AL-6 Pelican (IED) Bag";
        class assembleInfo {
            displayName = "";
            primary = 1;
            base = "";
            assembleTo = QGVAR(UAV_06_IED_I);
            dissasembleTo[] = {};
        };
    };


    // A SWARM IS AN EVENT, NOT A PRESENCE, which is the whole reason this is a
    // second module rather than a checkbox on the patrol one. JMSB - Drone
    // Patrol keeps a standing watch over ground, replaces losses and stands
    // down when nobody is near. This launches once, launches everything, and
    // what is gone is gone - which is what dropping a swarm on somebody means.
    //
    // TWO ACTIONS, AND THEY WANT DIFFERENT AIRFRAMES. Impact is a one-way
    // weapon and any airframe will do because the airframe IS the warhead;
    // circling is only worth doing with something armed, and those are left to
    // their own AI once they are on station.
    //
    // THE PICKER OFFERS WHAT THE SETTING ALLOWS. Which airframes a mission may
    // field is 1st Joint Multi-Functional Strike Battalion > Drones > Swarm airframes; this is how you
    // choose from it. A class off that list is refused when the module is
    // placed, not when it launches - the person who chose it is standing there.
    class jmfsb_moduleDroneSwarm: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Drone Swarm";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleDroneSwarm));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 1;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;
        icon = "\a3\ui_f\data\map\markers\nato\o_air.paa";

        class Attributes: AttributesBase {
            class swarmClass: Edit {
                property = QGVAR(swarmClass);
                displayName = "Airframe";
                tooltip = "Which drone the swarm is made of. The list is every UAV the game has; what a mission may actually field is the Swarm Airframes setting, and a class outside it is refused when this module is placed.";
                typeName = "STRING";
                control = "jmfsb_ClassPick_Uav_Single";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('swarmClass',_value)]);
            };
            class swarmCount: Edit {
                property = QGVAR(swarmCount);
                displayName = "Drones";
                tooltip = "How many. Two is the smallest thing worth calling a swarm; twelve is where a dozen airframes and their steering loops stop being a swarm and start being a frame time. Anything outside that is clamped.";
                typeName = "NUMBER";
                defaultValue = "4";
                expression = QUOTE(_this setVariable [ARR_2('swarmCount',_value)]);
            };
            class swarmAction: Combo {
                property = QGVAR(swarmAction);
                displayName = "Action";
                tooltip = "IMPACT: every drone dives on this module and detonates - shooting them down on the way in is the counterplay, and each one hit is one that does not arrive. CIRCLE: every drone orbits this module at height with its crew and its weapons, and is then left to its own AI. Circle wants an armed airframe.";
                typeName = "STRING";
                defaultValue = "impact";
                class values {
                    class valueImpact {
                        name = "Impact";
                        value = "impact";
                        default = 1;
                    };
                    class valueCircle {
                        name = "Circle";
                        value = "circle";
                    };
                };
                expression = QUOTE(_this setVariable [ARR_2('swarmAction',_value)]);
            };
            class spawnMin: Edit {
                property = QGVAR(spawnMin);
                displayName = "Spawn Min (m)";
                tooltip = "Nearest a drone may appear. Each rolls its own distance between this and the maximum, on its own bearing. Held at 500 m minimum: a swarm on top of its target is not a harder swarm, it is one nobody got to fight.";
                typeName = "NUMBER";
                defaultValue = "1500";
                expression = QUOTE(_this setVariable [ARR_2('spawnMin',_value)]);
            };
            class spawnMax: Edit {
                property = QGVAR(spawnMax);
                displayName = "Spawn Max (m)";
                tooltip = "Furthest a drone may appear. The transit from here is the window in which the swarm can be engaged - at the impact speed, 1500 m is about thirty seconds of it being someone's problem.";
                typeName = "NUMBER";
                defaultValue = "2500";
                expression = QUOTE(_this setVariable [ARR_2('spawnMax',_value)]);
            };
            class swarmSide: Edit {
                property = QGVAR(swarmSide);
                displayName = "Side";
                tooltip = "east, west, guer or civ. The airframe's own config decides the side of a drone that crews itself - this is the fallback crew's side for an airframe that comes out empty, so it wants to agree with the one you picked.";
                typeName = "STRING";
                defaultValue = "east";
                expression = QUOTE(_this setVariable [ARR_2('swarmSide',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "A swarm, launched where you place it. Trigger it to launch on cue.",
                "",
                "Airframe - which drone. Limited by the Swarm Airframes setting",
                "Drones - 2 to 12",
                "Action - Impact dives on this module; Circle orbits it",
                "Spawn Min / Max (m) - how far out they appear and fly in from",
                "Side - the fallback crew's side",
                "",
                "Resize the module to set the orbit radius. Impact ignores the area.",
            };
        };
    };
};
