#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {
            QGVAR(ACE_NVG_Wide),
            QGVAR(NVGoggles),
            QGVAR(NVGoggles_INDEP),
            QGVAR(NVGoggles_OPFOR),
            QGVAR(NVGoggles_tna_F),
            QGVAR(O_NVGoggles_hex_F),
            QGVAR(O_NVGoggles_urb_F)
        };
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_common",
            "cba_main",
            "ace_nightvision"
            // NO creator DLC here. The four LP NVGs that inherit EF's sets live
            // in compatibility/cdlc_ef and the RF Ti Goggles in compatibility/
            // cdlc_rf (tools/cdlc_split.py). This addon used to require EF's
            // A3_EFA_characters_f, so without EF loaded the whole of it - every
            // jmfsb NVG and the phosphor colour selection - silently skipped
            // (RPT: "Skipped loading of addon 'jmfsb_nvg'").
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {"YONV"};
        VERSION_CONFIG;
    };
};


#include "CfgEventHandlers.hpp"
#include "CfgEffects.hpp"
#include "CfgWeapons.hpp"
#include "XtdGear.hpp"
#include "gui.hpp"
