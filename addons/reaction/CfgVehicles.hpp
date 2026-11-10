class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // PLACING THIS MODULE IS THE ENABLE. No module, no enemy reaction - there is no
    // separate on switch to forget, and no system quietly running because a
    // setting defaulted to on in a mission that never asked for one.
    //
    // Every attribute here is an OPERATION value: how many, how often, how
    // likely. WHERE and WHO are never asked for - those come from ALiVE's own
    // commanders, their TAORs and their objectives, so this cannot be pointed
    // at ground its commander does not operate on.
    class jmfsb_moduleReaction: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Enemy Reaction";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_recon.paa";

        class Attributes: AttributesBase {
            class failChance: Edit {
                property = QGVAR(failChance);
                displayName = "Hack Fail Chance (%)";
                tooltip = "Chance an intrusion fails outright.";
                typeName = "NUMBER";
                defaultValue = "25";
                expression = QUOTE(_this setVariable [ARR_2('failChance',_value)]);
            };
            class detectChance: Edit {
                property = QGVAR(detectChance);
                displayName = "Detection Chance (%)";
                tooltip = "Chance a failure, a drone sighting or a transmission is noticed. The first notice is silent; the second brings the response.";
                typeName = "NUMBER";
                defaultValue = "50";
                expression = QUOTE(_this setVariable [ARR_2('detectChance',_value)]);
            };
            class roundsMin: Edit {
                property = QGVAR(roundsMin);
                displayName = "Barrage Rounds Min";
                tooltip = "Fewest shells a major response puts down.";
                typeName = "NUMBER";
                defaultValue = "4";
                expression = QUOTE(_this setVariable [ARR_2('roundsMin',_value)]);
            };
            class roundsMax: Edit {
                property = QGVAR(roundsMax);
                displayName = "Barrage Rounds Max";
                tooltip = "Most shells. The real count is rolled between the two.";
                typeName = "NUMBER";
                defaultValue = "10";
                expression = QUOTE(_this setVariable [ARR_2('roundsMax',_value)]);
            };
            class watts: Edit {
                property = QGVAR(watts);
                displayName = "Radio Watts Watched";
                tooltip = "Transmit power at or above which a radio can be direction-found. A game-voice key-up beyond the squad counts as 5 W; the squad net, the intercom and direct speech are never watched.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('watts',_value)]);
            };
            // COUNTER-BATTERY (user, 2026-10-25): PLAYER-CREWED guns only. The
            // players' virtual artillery (support batteries) is the exception, and
            // AI artillery never counts.
            class cbChance: Edit {
                property = QGVAR(cbChance);
                displayName = "Counter-Battery Chance (%)";
                tooltip = "Chance the enemy answers once its radar has fixed a player battery. 0 turns counter-battery off.";
                typeName = "NUMBER";
                defaultValue = "60";
                expression = QUOTE(_this setVariable [ARR_2('cbChance',_value)]);
            };
            class cbShots: Edit {
                property = QGVAR(cbShots);
                displayName = "Counter-Battery Rounds To Fix";
                tooltip = "Rounds one player-crewed gun fires inside the fix window before the enemy radar has it.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('cbShots',_value)]);
            };
            class cbWindow: Edit {
                property = QGVAR(cbWindow);
                displayName = "Counter-Battery Fix Window (s)";
                tooltip = "Those rounds have to come within this many seconds of the first.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('cbWindow',_value)]);
            };
            class cbDelayMin: Edit {
                property = QGVAR(cbDelayMin);
                displayName = "Counter-Battery Delay Min (s)";
                tooltip = "Soonest the answer lands after the fix. It falls where the guns were at the fix - shoot and move.";
                typeName = "NUMBER";
                defaultValue = "45";
                expression = QUOTE(_this setVariable [ARR_2('cbDelayMin',_value)]);
            };
            class cbDelayMax: Edit {
                property = QGVAR(cbDelayMax);
                displayName = "Counter-Battery Delay Max (s)";
                tooltip = "Latest. The real delay is rolled between the two.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('cbDelayMax',_value)]);
            };
            class cbRounds: Edit {
                property = QGVAR(cbRounds);
                displayName = "Counter-Battery Rounds";
                tooltip = "Shells in the answer when no enemy commander's guns can be asked.";
                typeName = "NUMBER";
                defaultValue = "6";
                expression = QUOTE(_this setVariable [ARR_2('cbRounds',_value)]);
            };
            class cbSpread: Edit {
                property = QGVAR(cbSpread);
                displayName = "Counter-Battery Spread (m)";
                tooltip = "Scatter radius of the answer round the fixed position.";
                typeName = "NUMBER";
                defaultValue = "75";
                expression = QUOTE(_this setVariable [ARR_2('cbSpread',_value)]);
            };
            class cbCooldown: Edit {
                property = QGVAR(cbCooldown);
                displayName = "Counter-Battery Cooldown (s)";
                tooltip = "After a fix, the same gun or battery is not tracked again for this long.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('cbCooldown',_value)]);
            };
            class cbWarn: Edit {
                property = QGVAR(cbWarn);
                displayName = "Counter-Battery Warning (1/0)";
                tooltip = "1: players at the fixed guns get an INCOMING notice when the answer is fired.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('cbWarn',_value)]);
            };
            // THE ENEMY'S GUNS, reported to the players' artillery team (a squad
            // whose ORBAT kind is art or mortar) as a TAC//MSG thread.
            class cbRadar: Edit {
                property = QGVAR(cbRadar);
                displayName = "Counter-Battery Radar Reports (1/0)";
                tooltip = "1: when enemy AI artillery fires, the players' artillery team (ORBAT squad kind art or mortar) gets its position as a TAC//MSG message, pinned on the map.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('cbRadar',_value)]);
            };
            class cbRadarError: Edit {
                property = QGVAR(cbRadarError);
                displayName = "Counter-Battery Radar Error (m)";
                tooltip = "The reported position is off the gun's true position by up to this.";
                typeName = "NUMBER";
                defaultValue = "100";
                expression = QUOTE(_this setVariable [ARR_2('cbRadarError',_value)]);
            };
            class cbRadarCooldown: Edit {
                property = QGVAR(cbRadarCooldown);
                displayName = "Counter-Battery Radar Cooldown (s)";
                tooltip = "One report per enemy gun per this many seconds.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('cbRadarCooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Placing this module turns on enemy reaction. Without it, the system is off.",
                "",
                "Hack Fail Chance (%) - Chance an intrusion fails outright",
                "Detection Chance (%) - Chance a failure, a drone sighting or a transmission is noticed",
                "Barrage Rounds Min - Fewest shells a major response puts down",
                "Barrage Rounds Max - Most shells",
                "Radio Watts Watched - Transmit power at or above which a radio can be direction-found",
                "",
                "Counter-battery - player-crewed guns only; the players' virtual artillery (support batteries called by message) and AI artillery never:",
                "Chance (%) - 0 turns it off. Rounds To Fix and Fix Window - how much fire the enemy radar needs",
                "Delay Min / Max (s) - when the answer lands, on where the guns were. Rounds, Spread - the answer",
                "Cooldown (s) - per gun. Warning (1/0) - INCOMING to the gun crew",
                "Radar Reports (1/0), Error (m), Cooldown (s) - every enemy shell (real guns and virtual barrages) is reported to the players' artillery team (ORBAT squad kind art or mortar) as a TAC//MSG message",
            };
        };
    };
};
