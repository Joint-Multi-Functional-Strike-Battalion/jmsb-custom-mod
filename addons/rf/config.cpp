#include "script_component.hpp"

// THE RF CORE: registry, link budget, mesh, client slices. Depends on CBA
// only; the voice adapters (jmfsb_voice / adapter_von), adapter_acre and every
// consumer depend on it.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "cba_xeh",
            "cba_settings"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
