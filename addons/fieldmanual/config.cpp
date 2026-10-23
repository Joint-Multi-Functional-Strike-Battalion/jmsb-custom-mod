#include "script_component.hpp"

// THE UNIT'S HOW-TO IN THE FIELD MANUAL (user, 2026-10-23: "there is a field
// manual in arma can we put all our how to data in there"). Config only: the
// entries are generated from the sign boards' own words by
// tools/gen_fieldmanual.py, with the boards as the pictures (jmfsb_media,
// jmfsb_fa_main), so the manual says what the signs say.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_media",
            "jmfsb_fa_main"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgHints.hpp"
