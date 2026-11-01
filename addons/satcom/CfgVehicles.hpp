class CBA_Extended_EventHandlers;

class CfgVehicles {
    class Land_SatelliteAntenna_01_F;

    // The planted mast. Vanilla model, so no art ships with this.
    class GVAR(deployed): Land_SatelliteAntenna_01_F {
        scope = 2;
        scopeCurator = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "SatCom Mast";
        model = "\A3\Props_F_Enoch\Military\Camps\SatelliteAntenna_01_F.p3d";
        icon = "iconObject_5x4";
        editorPreview = "\A3\EditorPreviews_F_Exp\Data\CfgVehicles\Land_SatelliteAntenna_01_F.jpg";
        // The CfgVehicleClasses entry main defines - NOT "jmfsb", which is the
        // faction class and left the engine with no displayName to read.
        vehicleClass = QUOTE(DOUBLES(PREFIX,Vehicles));
        mapSize = 3;

        class EventHandlers {
            class CBA_Extended_EventHandlers: CBA_Extended_EventHandlers {};
        };

        class ACE_Actions {
            class ACE_MainActions {
                selection = "interaction_point";
                distance = 5;
                condition = "true";

                class GVAR(pickUp) {
                    displayName = "Pack Up SatCom";
                    distance = 5;
                    condition = QUOTE([ARR_2(_player,_target)] call FUNC(canPickUp));
                    statement = QUOTE([ARR_2(_player,_target)] call FUNC(pickUp));
                    showDisabled = 0;
                    exceptions[] = {};
                    priority = 5;
                    icon = QPATHTOF(data\satcom_icon.paa);
                };
                // The ACRE2 Connect / Disconnect Radio actions were removed
                // with ACRE (DEC1, 2026-10-31).
            };
        };
    };

    class Man;
    class CAManBase: Man {
        class ACE_SelfActions {
            class ACE_Equipment {
                class GVAR(place) {
                    displayName = "Deploy SatCom";
                    condition = QUOTE([_player] call FUNC(canDeploy));
                    statement = QUOTE([_player] call FUNC(deploy));
                    exceptions[] = {};
                    showDisabled = 0;
                    icon = QPATHTOF(data\satcom_icon.paa);
                };
            };
        };
    };
};
