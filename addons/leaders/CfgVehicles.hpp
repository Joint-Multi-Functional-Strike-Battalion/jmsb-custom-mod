class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // PLACING THIS MODULE IS THE ENABLE. No module, no leader chain - there is no
    // separate on switch to forget, and no system quietly running because a
    // setting defaulted to on in a mission that never asked for one.
    //
    // Every attribute here is an OPERATION value: how many, how often, how
    // likely. WHERE and WHO are never asked for - those come from ALiVE's own
    // commanders, their TAORs and their objectives, so this cannot be pointed
    // at ground its commander does not operate on.
    class jmfsb_moduleLeaders: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Leader Chain";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_hq.paa";

        class Attributes: AttributesBase {
            class taor: Edit {
                property = QGVAR(taor);
                displayName = "TAOR Markers";
                tooltip = "Comma-separated area-marker names the safe houses and leaders must stay inside. BLANK reads the asymmetric commander's ALiVE placements - and if those come back empty, the chain goes map-wide, which is exactly what this field is for pinning down.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('taor',_value)]);
            };
            class poolCut: Edit {
                property = QGVAR(poolCut);
                displayName = "Pool Cut Per Leader (%)";
                tooltip = "How much of the asymmetric commander's force pool dies with each leader. Three leaders, finite - they do not come back.";
                typeName = "NUMBER";
                defaultValue = "25";
                expression = QUOTE(_this setVariable [ARR_2('poolCut',_value)]);
            };
            class rotateEvery: Edit {
                property = QGVAR(rotateEvery);
                displayName = "Rotate Every (sec)";
                tooltip = "How often a leader moves to another safe house.";
                typeName = "NUMBER";
                defaultValue = "1200";
                expression = QUOTE(_this setVariable [ARR_2('rotateEvery',_value)]);
            };
            class trapChance: Edit {
                property = QGVAR(trapChance);
                displayName = "Trap Chance (%)";
                tooltip = "Chance a watched safe house is trapped with mortars.";
                typeName = "NUMBER";
                defaultValue = "50";
                expression = QUOTE(_this setVariable [ARR_2('trapChance',_value)]);
            };
            class pops: Edit {
                property = QGVAR(pops);
                displayName = "Internet Pops";
                tooltip = "How many rugged-server props are placed for players to find and pull leads from.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('pops',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Placing this module turns on leader chain. Without it, the system is off.",
                "",
                "Without ALiVE: the mission's enemy is the insurgent side (or the side of a man synchronised to this module, whose faction the leaders wear), safe houses are in the map's towns, inside TAOR Markers or jmfsb_taor_west / _east / _guer markers when set.",
                "",
                "Pool Cut Per Leader (%) - How much of the asymmetric commander's force pool dies with each leader",
                "Rotate Every (sec) - How often a leader moves to another safe house",
                "Trap Chance (%) - Chance a watched safe house is trapped with mortars",
                "Internet Pops - How many rugged-server props are placed for players to find and pull leads from",
            };
        };
    };
};
