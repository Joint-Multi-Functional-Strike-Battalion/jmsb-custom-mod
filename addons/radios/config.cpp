#include "script_component.hpp"

// THE RADIO FAMILY. The MPU5 and TW-950 handhelds, and the MPU5 manpack for
// TFAR / ACRE only (no man packs under game voice, user 2026-10-21);
// the vehicle set and relay node follow on the same pattern
// (docs/SPEC_TACNET.json, radios).
//
// PLAIN ITEMS, NO RADIO MOD. Voice is Arma 3's own VON (docs/DESIGN_VOICE.md,
// D14): a handheld is a vanilla radio-slot item (ItemRadio, which is what
// opens VON's radio channels). Each names its
// RF profile (jmfsb_rf_profile), which is how jmfsb_rf recognises it as a set
// (jmfsb_rf_fnc_itemProfile). The class names are the ones loadouts, the PAC
// database and the arsenals already carry.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {"Item_jmfsb_mpu5", "Item_jmfsb_tw950", "jmfsb_mpu5_lr"};
        weapons[] = {"jmfsb_mpu5", "jmfsb_tw950"};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_backpack"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgWeapons.hpp"
#include "CfgVehicles.hpp"
