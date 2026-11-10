class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // PLACING THIS MODULE IS THE ENABLE. No module, no qrf - there is no
    // separate on switch to forget, and no system quietly running because a
    // setting defaulted to on in a mission that never asked for one.
    //
    // Every attribute here is an OPERATION value: how many, how often, how
    // likely. WHERE and WHO are never asked for - those come from ALiVE's own
    // commanders, their TAORs and their objectives, so this cannot be pointed
    // at ground its commander does not operate on.
    class jmfsb_moduleQRF: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - QRF";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_mech_inf.paa";

        class Attributes: AttributesBase {
            class holdTime: Edit {
                property = QGVAR(holdTime);
                displayName = "Hold Time (sec)";
                tooltip = "How long players must hold an objective, uncontested, before it counts as taken.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('holdTime',_value)]);
            };
            class minPlayers: Edit {
                property = QGVAR(minPlayers);
                displayName = "Players Needed";
                tooltip = "How many players inside before a hold counts at all.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('minPlayers',_value)]);
            };
            class squadsMin: Edit {
                property = QGVAR(squadsMin);
                displayName = "Squads Min";
                tooltip = "Fewest squads the third wave sends.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('squadsMin',_value)]);
            };
            class squadsMax: Edit {
                property = QGVAR(squadsMax);
                displayName = "Squads Max";
                tooltip = "Most squads. Rolled between the two.";
                typeName = "NUMBER";
                defaultValue = "5";
                expression = QUOTE(_this setVariable [ARR_2('squadsMax',_value)]);
            };
            class asymMortarChance: Edit {
                property = QGVAR(asymMortarChance);
                displayName = "Asymmetric Mortar Chance (%)";
                tooltip = "An asymmetric commander answers with a few mortar rounds or with nothing - never a full barrage.";
                typeName = "NUMBER";
                defaultValue = "50";
                expression = QUOTE(_this setVariable [ARR_2('asymMortarChance',_value)]);
            };
            class cooldown: Edit {
                property = QGVAR(cooldown);
                displayName = "Cooldown (sec)";
                tooltip = "Retaking the same objective inside this window brings no second QRF.";
                typeName = "NUMBER";
                defaultValue = "1800";
                expression = QUOTE(_this setVariable [ARR_2('cooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Placing this module turns on qrf. Without it, the system is off.",
                "",
                "Without ALiVE: only jmfsb_qrf area markers are watched, the mission's enemy answers, and its squads walk in live. No artillery is asked - there are no commander's guns.",
                "",
                "Hold Time (sec) - How long players must hold an objective, uncontested, before it counts as taken",
                "Players Needed - How many players inside before a hold counts at all",
                "Squads Min - Fewest squads the third wave sends",
                "Squads Max - Most squads",
                "Asymmetric Mortar Chance (%) - An asymmetric commander answers with a few mortar rounds or with nothing - never a full barrage",
                "Cooldown (sec) - Retaking the same objective inside this window brings no second QRF",
            };
        };
    };
};
