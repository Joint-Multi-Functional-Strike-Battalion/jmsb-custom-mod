// ACE3 Arsenal Extended: the JMSB Vector designators as one model (user,
// 2026-10-17: "extended arsenal configs for our goggles and binos") - the
// arsenal switch moves between the NVG/TI and the NVG version, never back to
// ACE's own Vector.
class XtdGearModels {
    class CfgWeapons {
        class GVAR(vector_designator) {
            label = "[JMSB] Vector Designator";
            options[] = {"vision"};
            class vision {
                label = "Vision";
                alwaysSelectable = 1;
                values[] = {"nvgti", "nvg"};
                class nvgti {
                    label = "NVG / Thermal";
                };
                class nvg {
                    label = "NVG";
                };
            };
        };
    };
};

class XtdGearInfos {
    class CfgWeapons {
        class GVAR(Vector_Designator) {
            model = QGVAR(vector_designator);
            vision = "nvgti";
        };
        class GVAR(Vector_Designator_NVG) {
            model = QGVAR(vector_designator);
            vision = "nvg";
        };
    };
};
