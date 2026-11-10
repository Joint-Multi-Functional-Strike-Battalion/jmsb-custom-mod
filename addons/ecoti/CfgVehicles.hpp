class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Combo;
        };
        class ModuleDescription;
    };

    // A BUILDING EVERY AITR HIGHLIGHTS (user, 2026-11-06: "add a way in 3den,
    // zeus and by players to make a building that this is highligheted in
    // ecoti"). Placed on a building in Eden, or by a Zeus; synced buildings are
    // marked instead of the nearest. Players mark with their own key, the
    // colour asked on numpad 6-9 (FUNC(markKey)).
    class GVAR(moduleMark): Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - AiTR Building Mark";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QFUNC(moduleMark);
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\military\box_ca.paa";

        class Attributes: AttributesBase {
            class colour: Combo {
                property = QGVAR(markColour);
                displayName = "Colour";
                tooltip = "The box every AiTR draws round the building.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('colour',_value)]);
                class Values {
                    class red { name = "Red"; value = 0; default = 1; };
                    class blue { name = "Blue"; value = 1; };
                    class green { name = "Green"; value = 2; };
                    class yellow { name = "Yellow"; value = 3; };
                    class white { name = "White"; value = 4; };
                    class orange { name = "Orange"; value = 5; };
                    class purple { name = "Purple"; value = 6; };
                };
            };
            class label: Edit {
                property = QGVAR(markLabel);
                displayName = "Label";
                tooltip = "Under the box, with the range - OBJ ALPHA, HVT. Empty: MARK.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('label',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Marks a building for every AiTR (ECOTI): a box round it in the Colour, the Label and range under it, out to 2 km, through walls.",
                "",
                "Place it on the building, or sync buildings to it. Nothing synced: the nearest building within 25 m.",
                "",
                "Players mark from their own key (AiTR - mark building) and pick the colour on numpad 6-9 on the phone or side device. A Zeus with ZEN has a dialog: 1st Joint Multi-Functional Strike Battalion > AiTR building mark."
            };
        };
    };
};
