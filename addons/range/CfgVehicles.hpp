class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class ArgumentsBaseUnits;
        class ModuleDescription;
    };

    // ONE SHOOTING RANGE. Sync its pop-up targets and the object players walk
    // up to (a laptop, a sign, a table) to the module, or name them below.
    // The controller gets the ACE menu: mode, setting, start, stop.
    class GVAR(module): Module_F {
        scope = 2;
        displayName = "JMSB - Shooting Range";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleInit);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        class Arguments: ArgumentsBaseUnits {
            class name {
                displayName = "Range name";
                description = "Shown in the menu, the results and the PAC record. Keep it the same between missions so scores line up.";
                typeName = "STRING";
                defaultValue = "";
            };
            class targets {
                displayName = "Targets";
                description = "Pop-up target variable names, comma separated. Synced pop-up targets are added to these.";
                typeName = "STRING";
                defaultValue = "";
            };
            class controllers {
                displayName = "Controllers";
                description = "Objects that get the range menu, comma separated. Synced objects that are not targets are added to these.";
                typeName = "STRING";
                defaultValue = "";
            };
            class mode {
                displayName = "Default mode";
                description = "The mode the menu starts on.";
                typeName = "NUMBER";
                class values {
                    class timed {
                        name = "Pop-ups, timed";
                        value = 1;
                        default = 1;
                    };
                    class count {
                        name = "Pop-ups, set number";
                        value = 2;
                    };
                    class rampage {
                        name = "Rampage - all up, clear them";
                        value = 3;
                    };
                };
            };
            class durations {
                displayName = "Durations";
                description = "Run lengths offered, seconds, comma separated. Timed runs last this long; a rampage is cut off at it.";
                typeName = "STRING";
                defaultValue = "30,60,120";
            };
            class duration {
                displayName = "Default duration";
                description = "Seconds.";
                typeName = "NUMBER";
                defaultValue = "60";
            };
            class counts {
                displayName = "Target numbers";
                description = "How many pop-ups a set-number run shows, comma separated.";
                typeName = "STRING";
                defaultValue = "10,20,40";
            };
            class count {
                displayName = "Default target number";
                description = "Pop-ups in a set-number run.";
                typeName = "NUMBER";
                defaultValue = "20";
            };
            class exposures {
                displayName = "Exposure times";
                description = "How long a pop-up stays up, seconds, comma separated.";
                typeName = "STRING";
                defaultValue = "2,3,5";
            };
            class exposure {
                displayName = "Default exposure";
                description = "Seconds a pop-up stays up.";
                typeName = "NUMBER";
                defaultValue = "3";
            };
            class countdown {
                displayName = "Countdown";
                description = "Seconds from Start to the first target.";
                typeName = "NUMBER";
                defaultValue = "5";
            };
            class savePac {
                displayName = "Save score to PAC";
                description = "Keep each finished run on the shooter's PAC record, under this range's name.";
                typeName = "BOOL";
                class values {
                    class yes {
                        name = "Yes";
                        value = 1;
                        default = 1;
                    };
                    class no {
                        name = "No";
                        value = 0;
                    };
                };
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "A shooting range: sync its pop-up targets and a controller object. The controller gets the range menu.";
        };
    };

    // THE POP-UP TARGETS' HIT HANDLER, replaced. The game's own drops the
    // target and pops it back up; FUNC(handleHit) does the same off a range,
    // and on a running range counts the shooter's hits instead.
    class TargetBase;
    class TargetP_Inf_F: TargetBase {
        class EventHandlers {
            hitPart = QUOTE((_this select 0) call FUNC(handleHit));
        };
    };
};
