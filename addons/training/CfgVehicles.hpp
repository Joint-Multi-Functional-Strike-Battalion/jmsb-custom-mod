class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class ArgumentsBaseUnits;
        class ModuleDescription;
    };

    // TRAINING: spawn and garrison troops in an area, live. The mission holds
    // the info - where (this module's area or a marker) and what (CfgGroups
    // classes). Sync a trigger to spawn on it, as often as it fires; with no
    // trigger it spawns at mission start. No ALiVE.
    class GVAR(moduleGarrison): Module_F {
        scope = 2;
        displayName = "JMSB - Garrison Area";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleGarrison);
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 1;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;

        class AttributeValues {
            size3[] = {100, 100, -1};
            IsRectangle = 0;
        };

        class Arguments: ArgumentsBaseUnits {
            class groups {
                displayName = "Groups";
                description = "CfgGroups class names, comma separated. One is picked at random for each group.";
                typeName = "STRING";
                defaultValue = "";
            };
            class count {
                displayName = "Group count";
                description = "How many groups each time it fires.";
                typeName = "NUMBER";
                defaultValue = "2";
            };
            class marker {
                displayName = "Marker";
                description = "Area marker to use instead of this module's area. Blank = this module's area.";
                typeName = "STRING";
                defaultValue = "";
            };
            class patrol {
                displayName = "Patrol chance";
                description = "Chance each man patrols instead of taking a building (0-1).";
                typeName = "NUMBER";
                defaultValue = "0.2";
            };
            class hold {
                displayName = "Hold chance";
                description = "Chance each man stays in his building when fighting starts (0-1).";
                typeName = "NUMBER";
                defaultValue = "0.5";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Spawns groups in the area and garrisons its buildings. Sync a trigger to spawn when it fires.";
            sync[] = {"LocationArea_F"};

            class LocationArea_F {
                position = 1;
                optional = 1;
                duplicate = 0;
                synced[] = {"EmptyDetector"};
            };
        };
    };

    // TRAINING AREA (user, 2026-11-07: "make it a module with all the choices
    // in it instead of markers"): one for each area the TAC//TRAINING app
    // offers. The module's own area is the area; the rest is what the trainer
    // starts with and may choose from. Nothing spawns until he presses SPAWN.
    class GVAR(moduleArea): Module_F {
        scope = 2;
        displayName = "JMSB - Training Area";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleArea);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;

        class AttributeValues {
            size3[] = {75, 75, -1};
            IsRectangle = 0;
        };

        class Arguments: ArgumentsBaseUnits {
            class name {
                displayName = "Name";
                description = "Shown in the TAC//TRAINING app. Blank: AREA and its grid.";
                typeName = "STRING";
                defaultValue = "";
            };
            class type {
                displayName = "Type";
                description = "What the enemy does in it. CQB: still in rooms, a few move once shots are near. City: teams garrison buildings, a share walk the streets. Patrol: teams patrol. Base: guards, perimeter patrols, statics and armed vehicles.";
                typeName = "NUMBER";
                class values {
                    class cqb {name = "CQB / shoot house"; value = 0; default = 1;};
                    class city {name = "City"; value = 1;};
                    class patrol {name = "Patrol"; value = 2;};
                    class base {name = "Base"; value = 3;};
                };
            };
            class density {
                displayName = "Default density";
                description = "Where the app's density starts. The count is worked out from the area's buildings and size.";
                typeName = "NUMBER";
                class values {
                    class light {name = "Light"; value = 0;};
                    class medium {name = "Medium"; value = 1; default = 1;};
                    class heavy {name = "Heavy"; value = 2;};
                };
            };
            class faction {
                displayName = "Default faction";
                description = "CfgFactionClasses class the app starts on, e.g. OPF_F. Blank: the first one offered.";
                typeName = "STRING";
                defaultValue = "";
            };
            class factions {
                displayName = "Factions offered";
                description = "CfgFactionClasses classes the trainer may pick, comma separated. Blank: every faction not on his side.";
                typeName = "STRING";
                defaultValue = "";
            };
            class patrol {
                displayName = "Default patrol radius (m)";
                description = "Where the app's patrol radius past the edge starts. Not used for CQB.";
                typeName = "NUMBER";
                defaultValue = "0";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "A training area for the TAC//TRAINING app: its area, type and the enemy choices the trainer starts with.";
        };
    };

    // MEDICAL TRAINING (user, 2026-11-07: "make the medical simulator a module
    // where you pick the name of the spawn points"): one per aid station. The
    // TAC//TRAINING app's PATIENTS tab puts casualties on these points - the
    // objects named here, and any synced to the module (stretchers, beds,
    // helipads...).
    class GVAR(moduleMedical): Module_F {
        scope = 2;
        displayName = "JMSB - Medical Training";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleMedical);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        class Arguments: ArgumentsBaseUnits {
            class name {
                displayName = "Station name";
                description = "Shown in the app over its points, e.g. AID STATION 1. Blank: MEDICAL and its grid.";
                typeName = "STRING";
                defaultValue = "";
            };
            class points {
                displayName = "Spawn points";
                description = "Variable names of the objects patients are put on, comma separated, in the order the app lists them, e.g. stretcher_1, stretcher_2. Objects synced to this module are added after them. A synced laptop is not a point: it is the station's terminal - anyone can spawn patients on these points from its ACE menu.";
                typeName = "STRING";
                defaultValue = "";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "An aid station for the TAC//TRAINING app: the points patients are spawned on - named in Spawn points, or synced. Sync a laptop for anyone, not only NCOs, to spawn patients here.";
        };
    };

    // VEHICLE RANGE (user, 2026-11-07: "a spawn for vehicles, no ammo ... move
    // north to south or east to west ... at the edge they turn around ... a
    // despawn"): moving targets for the TAC//TRAINING app. The module's own
    // area is the range; nothing spawns until the trainer presses SPAWN.
    class GVAR(moduleVehicles): Module_F {
        scope = 2;
        displayName = "JMSB - Vehicle Range";
        author = QAUTHOR;
        vehicleClass = "Modules";
        category = QPREFIX;
        function = QFUNC(moduleVehicles);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;

        class AttributeValues {
            size3[] = {150, 300, -1};
            IsRectangle = 1;
        };

        class Arguments: ArgumentsBaseUnits {
            class name {
                displayName = "Name";
                description = "Shown in the TAC//TRAINING app. Blank: RANGE and its grid.";
                typeName = "STRING";
                defaultValue = "";
            };
            class vehicles {
                displayName = "Vehicles";
                description = "CfgVehicles class names, comma separated, e.g. O_MRAP_02_F, O_APC_Tracked_02_cannon_F. Picked in turn for each vehicle spawned. Spawned with their own crew, no ammo.";
                typeName = "STRING";
                defaultValue = "";
            };
            class direction {
                displayName = "Direction";
                description = "Which way they drive first. At the far edge they turn round and drive back, edge to edge, until destroyed or despawned.";
                typeName = "NUMBER";
                class values {
                    class ns {name = "North to south"; value = 0; default = 1;};
                    class sn {name = "South to north"; value = 1;};
                    class ew {name = "East to west"; value = 2;};
                    class we {name = "West to east"; value = 3;};
                    class nesw {name = "Northeast to southwest"; value = 4;};
                    class swne {name = "Southwest to northeast"; value = 5;};
                    class nwse {name = "Northwest to southeast"; value = 6;};
                    class senw {name = "Southeast to northwest"; value = 7;};
                };
            };
            class count {
                displayName = "Vehicles at once";
                description = "How many spawn side by side, 1-8. The app starts on this.";
                typeName = "NUMBER";
                defaultValue = "2";
            };
            class speed {
                displayName = "Speed (km/h)";
                description = "How fast they drive. The app starts on this.";
                typeName = "NUMBER";
                defaultValue = "30";
            };
            class despawn {
                displayName = "Despawn after (minutes)";
                description = "Vehicles, crews and wrecks are removed this long after SPAWN. 0: only by DESPAWN in the app.";
                typeName = "NUMBER";
                defaultValue = "30";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "A vehicle range for the TAC//TRAINING app: vehicles with no ammo drive edge to edge across the area and back. SPAWN and DESPAWN from the app.";
        };
    };
};
