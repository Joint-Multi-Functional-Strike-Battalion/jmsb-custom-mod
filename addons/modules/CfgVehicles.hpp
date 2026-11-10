class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class ArgumentsBaseUnits;
        class ModuleDescription;
    };

    class jmfsb_modulesafestart: Module_F {
        scope = 2;
        displayName = "Safe Start Disabler";
        author = "Brecon";
        vehicleClass = "Modules";
        category = QPREFIX;
        function =  QUOTE(DFUNC(moduleSafeStart));
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;
        canSetArea = 1;

        class AttributeValues {
            size3[] = {25,50,-1};
            IsRectangle = 1;
        };

        class Arguments: ArgumentsBaseUnits {
            class spDisable {
                displayName = "SP Disable";
                description = "Disable in single player";
                typeName = "BOOL";
                class values {
                    class valueEnabled {
                        name = "Enable";
                        value = "true";
                        default = "true";
                    };
                    class valueDisabled {
                        name = "Disable";
                        value = "false";
                    };
                };
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Disable Safe Start";
            sync[] = {"LocationArea_F"};

            class LocationArea_F {
                position = 1;
                optional = 1;
                duplicate = 0;
                synced[] = {"Anything"};
            };
        };
    };

    class jmfsb_moduleHealArea: Module_F {
        scope = 2;
        displayName = "Heal Area";
        author = "Brecon";
        vehicleClass = "Modules";
        category = QPREFIX;
        function =  QUOTE(DFUNC(moduleHealArea));
        icon = "\z\jmfsb\addons\media\images\Icons\MedicalArea.paa";
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;
        canSetArea = 1;

        class AttributeValues {
            size3[] = {25,25,-1};
            IsRectangle = 1;
        };

        class ModuleDescription: ModuleDescription {
            description = "Heal Players In Area";
            sync[] = {"LocationArea_F"};

            class LocationArea_F {
                position = 1;
                optional = 1;
                duplicate = 0;
                synced[] = {"Anything"};
            };
        };
    };

    class jmfsb_moduleAiSpawner: Module_F {
        scope = 2;
        displayName = "AI Spawner";
        author = "Brecon";
        vehicleClass = "Modules";
        category = QPREFIX;
        function =  QUOTE(DFUNC(moduleAiSpawner));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 1;
        isDisposable = 0;
        is3DEN = 0;

        class Arguments: ArgumentsBaseUnits {
            class groupSide {
                displayName = "Side";
                description = "Group Side";
                typeName = "SIDE";
                class values {
                    class sideWest {
                        name = "WEST";
                        value = "WEST";
                        default = 1;
                    };
                    class sideEast {
                        name = "EAST";
                        value = "EAST";
                    };
                    class sideIndep {
                        name = "INDEPENDENT";
                        value = "INDEPENDENT";
                    };
                    class sideCiv {
                        name = "CIVILIAN";
                        value = "CIVILIAN";
                    };
                };
            };

            class groupConfig {
                displayName = "Group Config";
                description = "Group Config";
                typeName = "CONFIG";
                defaultValue = "configFile >> ""CfgGroups"" >> ""West"" >> ""BLU_F"" >> ""Infantry"" >> ""BUS_InfSquad""";
            };

            class moveMarker1 {
                displayName = "Move Marker 1";
                description = "Move Marker 1";
                typeName = "STRING";
                defaultValue = "";
            };

            class moveMarker2 {
                displayName = "Move Marker 2";
                description = "Move Marker 2";
                typeName = "STRING";
                defaultValue = "";
            };

            class waves {
                displayName = "Waves";
                description = "-1 for Unlimited";
                typeName = "NUMBER";
                defaultValue = -1;
            };

            class huntCondition {
                displayName = "Hunt Condition";
                description = "Condition for AI to start hunting players and stops respawning";
                typeName = "STRING";
                defaultValue = "false";
            };

            class huntTrigger {
                displayName = "Hunt Trigger";
                description = "Hunt Trigger";
                typeName = "STRING";
                defaultValue = "jmfsb_huntTrigger";
            };
            class sadTrigger {
                displayName = "SAD Trigger";
                description = "Search and Destroy Trigger";
                typeName = "STRING";
                defaultValue = "sadTrigger0";
            };

            // The controller always read this attribute - "the same spawn,
            // straight after the players" - but no module ever declared it,
            // so the path was unreachable from Eden.
            class startHunting {
                displayName = "Hunt Immediately";
                description = "Skip the route: the group goes straight after the players from the first wave.";
                typeName = "BOOL";
                defaultValue = 0;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Ai Spawner";
            sync[] = {"LocationArea_F"};

            class LocationArea_F {
                position = 0;
                optional = 0;
                duplicate = 1;
                synced[] = {"Anything"};
            };
        };
    };

    class jmfsb_moduleAiHunter: Module_F {
        scope = 2;
        displayName = "AI Hunter";
        author = "Brecon";
        vehicleClass = "Modules";
        category = QPREFIX;
        function =  QUOTE(DFUNC(moduleAiHunter));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 1;
        isDisposable = 0;
        is3DEN = 0;

        class Arguments: ArgumentsBaseUnits {
            class groupSide {
                displayName = "Side";
                description = "Group Side";
                typeName = "SIDE";
                class values {
                    class sideWest {
                        name = "WEST";
                        value = "WEST";
                        default = 1;
                    };
                    class sideEast {
                        name = "EAST";
                        value = "EAST";
                    };
                    class sideIndep {
                        name = "INDEPENDENT";
                        value = "INDEPENDENT";
                    };
                    class sideCiv {
                        name = "CIVILIAN";
                        value = "CIVILIAN";
                    };
                };
            };

            class groupConfig {
                displayName = "Group Config";
                description = "Group Config";
                typeName = "CONFIG";
                defaultValue = "configFile >> ""CfgGroups"" >> ""West"" >> ""BLU_F"" >> ""Infantry"" >> ""BUS_InfSquad""";
            };

            class waves {
                displayName = "Waves";
                description = "-1 for Unlimited";
                typeName = "NUMBER";
                defaultValue = -1;
            };

            class huntTrigger {
                displayName = "Hunt Trigger";
                description = "Hunt Trigger";
                typeName = "STRING";
                defaultValue = "jmfsb_huntTrigger";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Ai Hunter";
            sync[] = {"LocationArea_F"};

            class LocationArea_F {
                position = 0;
                optional = 0;
                duplicate = 1;
                synced[] = {"Anything"};
            };
        };
    };

    // TRAINING: ALiVE stands up paused, and nothing jmfsb starts on ALiVE
    // starts, until an admin types #jmfsbalivestart. Placed = held; no
    // attributes. Does nothing without ALiVE.
    class GVAR(holdAlive): Module_F {
        scope = 2;
        displayName = "JMSB - Hold ALiVE";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleHoldAlive);
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        class ModuleDescription: ModuleDescription {
            description = "Training: ALiVE starts paused. An admin types #jmfsbalivestart in chat to start it.";
        };
    };
};
