#include "script_component.hpp"
/*
 * Author: JMSB
 * Tells the suite where to draw: the rectangle, in screen units, and the
 * display. With no arguments it is the safe zone and no display, which is the
 * native host - FUNC(hostDisplay) answers with the vanilla map in that mode and
 * never reads the stored display.
 *
 * jmfsb_devices calls this with its dialog and the screen rectangle inside the
 * frame before it calls FUNC(open), and again with nothing when the dialog
 * unloads, so the host never points at a display that has gone.
 *
 * THE RECTANGLE IS ALWAYS VALID. The HOST_* macros index it without checking,
 * and FUNC(textH) is called from outside the suite - the HUD sizes its rows off
 * it - so an empty host would throw in code that never opened a panel.
 *
 * Arguments:
 * 0: Host rectangle [x, y, w, h] in screen units, [] for the safe zone <ARRAY> (optional, default [])
 * 1: Host display, displayNull for the vanilla map <DISPLAY> (optional, default displayNull)
 * 2: Fixed panel places on this host, panel id -> [x, y, w, h] in host fractions, or [] for a panel the host
 *    does not want built - see FUNC(place) and FUNC(open) <HASHMAP> (optional, default empty: every panel at its default)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_mapArea, _display, _places] call jmfsb_tacpad_fnc_setHost
 *
 * Public: Yes
 */

params [["_rect", [], [[]]], ["_display", displayNull, [displayNull]], ["_places", createHashMap, [createHashMap]]];

if (count _rect != 4) then {
    _rect = [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
};

GVAR(host) = _rect;

// A HOST THAT GOES TAKES ITS OPEN APP WITH IT. The app was drawn on the display
// that is going, and appCurrent lives in uiNamespace: left set, the next host
// builds every panel hidden behind a screen that is not there, and a screen
// adopted with FUNC(appHost) - the reader, TAC//PAC - keeps pointing at a dead
// display. Only on a real change, or the device handing back: the vanilla map
// re-hands the safe zone on every open, and an app reopened on top of that
// rebuild must survive it.
private _stored = uiNamespace getVariable [QGVAR(hostDisplay), displayNull];
if (_display isNotEqualTo _stored || {isNull _display && HOST_DEVICE}) then {
    private _was = uiNamespace getVariable [QGVAR(appCurrent), ""];
    uiNamespace setVariable [QGVAR(appCurrent), ""];
    uiNamespace setVariable [QGVAR(appGroup), controlNull];
    uiNamespace setVariable [QGVAR(appMapClaim), ""];
    if (_was isNotEqualTo "") then {
        [QGVAR(appClosed), [_was]] call CBA_fnc_localEvent;
    };
};

uiNamespace setVariable [QGVAR(hostDisplay), _display];

// A DEVICE'S OWN LAYOUT TABLE. The tablet's panels are not draggable and do not
// sit where the safe-zone defaults put them: they have fixed places in its map
// area (docs/DESIGN_TABLET.md, "Map area"), handed over with the host and
// dropped with it, so the vanilla map never sees them.
GVAR(hostPlaces) = _places;
