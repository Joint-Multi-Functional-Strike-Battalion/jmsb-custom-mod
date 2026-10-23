#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {QGVAR(phone), QGVAR(side), QGVAR(side2)};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_xeh"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

// THE FRAMES. One class per device: its texture and, as fractions of that
// texture, where the device body is and where its screen is. Generated from the
// renders by tools/art/devices/gen_devices.py, which measures the screen off
// the bezel rather than trusting a number typed from an older render - two of
// the spec's rects were stale that way.
class CfgJmfsbDevices {
    #include "frames.hpp"
};

#include "dialog.hpp"

// THE WALKING VIEW and the items that carry it - see overlay.hpp.
#include "overlay.hpp"
#include "CfgWeapons.hpp"
