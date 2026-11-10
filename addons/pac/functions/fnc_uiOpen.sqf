#include "script_component.hpp"
/*
    File: fnc_uiOpen.sqf
    Author: YonV
    Description: Open TAC//PAC - the one dialog (ui/pac.inc.hpp).

        IT OPENS ON THE DASHBOARD, as the website does, and the nav bar along
        the top goes everywhere else. Admins only, the same as the website's
        admin pages; a player's own record, the roster and PAC requests are
        in the tacpad's PAC app (FUNC(app)): the tablet bar's PAC button, the
        PAC tile on the map (user, 2026-11-01).

        INSIDE THE TABLET when the tacpad's host is a device that is open
        (user, 2026-10-20: "all apps need to be inside the tablet") - the same
        controls, drawn on the device dialog as its open app (FUNC(uiHost)).
        Everywhere else, the dialog.

    Parameters:
        0: Page to open on <STRING> (optional, default "dashboard")
        1: Page arguments <HASHMAP> (optional)

    Returns:
        Whether it opened <BOOL>
*/

params [["_page", "dashboard", [""]], ["_args", createHashMap, [createHashMap]]];

if (!hasInterface) exitWith {false};
if (isNil "jmfsb_adminpanel_fnc_isAdmin" || {!([player] call jmfsb_adminpanel_fnc_isAdmin)}) exitWith {
    ["TAC//PAC", "Admins only - PAC on the tablet's top bar (the PAC tile on the map) has your record, the roster and PAC requests.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify);
    false
};

GVAR(uiHistory) = [];
GVAR(uiPage) = _page;
GVAR(uiArgs) = _args;
GVAR(uiData) = createHashMap;

if (HOST_DEVICE && {!isNull (HOST_DISPLAY)}) exitWith {[] call FUNC(uiHost)};

createDialog QGVAR(pac)
