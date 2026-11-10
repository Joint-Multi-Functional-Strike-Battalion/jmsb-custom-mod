#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            // XEH_preInit seeds the profile through
            // EFUNC(common,runAfterSettingsInit) - a nil EFUNC target resolves
            // to nothing rather than erroring, so without this the quick
            // connect settings would silently never reach the main menu
            "jmfsb_common",
            // the holiday crest table and EFUNC(loading,holiday), asked by
            // XEH_mainDisplay for the crest above the buttons
            "jmfsb_loading"
        };
        author = QAUTHOR;
        authors[] = {"veteran29"};
        VERSION_CONFIG;
    };
};

class CfgCommands {
    allowedHTMLLoadURIs[] += {
        URL
    };
};


#include "CfgEventHandlers.hpp"
#include "CfgMenus.hpp"
#include "gui.hpp"
