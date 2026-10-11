class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Combo;
            class Edit;
        };
        class ModuleDescription;
    };

    // ------------------------------------------------------------------------
    // ACM Evacuation Zone (user, 2026-10-09): drop it, size it, and any AI
    // that enters the area is evacuated the way ACM's own "Evacuate patient"
    // action does it - on foot, carried, or sitting in a vehicle. A converted
    // casualty also earns its side back the casualty ticket, as ACM's action does.
    // ------------------------------------------------------------------------
    class GVAR(moduleEvacZone): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - ACM Evacuation Zone";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QFUNC(moduleEvacZone);
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        canSetArea = 1;
        canSetAreaShape = 1;
        icon = "\A3\ui_f\data\map\markers\nato\b_med.paa";

        class AttributeValues {
            size3[] = {50, 50, -1};
            isRectangle = 0;
        };

        class Attributes: AttributesBase {
            class who: Combo {
                property = QGVAR(evacZoneWho);
                displayName = "Who Is Evacuated";
                tooltip = "EVERY AI: any AI unit inside the area is evacuated, conscious or not, in a vehicle or on foot. CASUALTIES ONLY: only an AI that is unconscious or has been converted to a casualty - the pilot or driver who brought them stays. Players are never evacuated.";
                typeName = "STRING";
                defaultValue = "'all'";
                expression = QUOTE(_this setVariable [ARR_2('who',_value)]);
                class Values {
                    class all        { name = "Every AI";        value = "all"; };
                    class casualties { name = "Casualties only"; value = "casualties"; };
                };
            };
            class interval: Edit {
                property = QGVAR(evacZoneInterval);
                displayName = "Check Every (s)";
                tooltip = "How often the server looks for AI inside the area, in seconds. Shorter catches a unit sooner; longer costs less. At least 1.";
                typeName = "NUMBER";
                defaultValue = "6";
                expression = QUOTE(_this setVariable [ARR_2('interval',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Any AI that enters the area is evacuated with ACM's evacuation: removed from the mission, out of a vehicle if it is in one, and a converted casualty returns its casualty ticket. Players are never touched. The zone is marked on everyone's map (EVAC).";
        };
    };
};
