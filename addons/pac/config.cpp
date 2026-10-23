#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_adminpanel",
            "jmfsb_tacpad",
            "jmfsb_notify"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

// The admin page inherits the console's control classes so the two screens are
// one family - same type, same edges, same combos - and repaints itself from the
// same tacpad theme.
// Vanilla bases for the boot screen RscTitles (ui/bootscreen.hpp).
class RscText;
class RscPicture;
class RscStructuredText;

class RscADMPText;
class RscADMPButton;
class RscADMPEdit;
class RscADMPCombo;
class RscADMPStructuredText;
// The table with real columns the one dialog draws every list in.
class RscListNBox;
// The shell group every control of the one dialog sits in, so the same
// controls can be created inside the tablet (ui/pac.inc.hpp, GVAR(shell)).
class RscControlsGroupNoScrollbars;

// ONE DIALOG (2026-09-09): the website's shell - bar, page, actions - and
// every page drawn in it. The personnel panel, EDIT STRUCTURE, MANAGE and the
// dashboard it replaced are gone.
#include "ui\pac.inc.hpp"
#include "ui\bootscreen.hpp"
