#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // ace_interact_menu for the action, ace_common for progressBar/goKneeling,
        // ace_medical for setUnconscious, ace_medical_treatment for isMedic + fullHeal.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "ace_interact_menu",
            "ace_common",
            "ace_medical",
            "ace_medical_treatment"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
