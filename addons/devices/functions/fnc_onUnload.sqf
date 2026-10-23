#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet dialog has closed - ESC, FUNC(close), or anything else that closes
 * a dialog. Takes the suite down and gives the shell its native host back, so
 * nothing in it points at a display that has gone.
 *
 * The controls die with the display; this is bookkeeping. The shell's close
 * drops its references and stops the refresh loop, which is the one thing that
 * would otherwise still be ticking an hour later.
 *
 * Arguments:
 * 0: The dialog's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

[] call EFUNC(tacpad,close);

// The tablet rows' tick (FUNC(tabletChrome)) would stop itself on the next
// run against a dead display; stopped here so it never gets one.
if (GVAR(tabletPFH) isNotEqualTo -1) then {
    [GVAR(tabletPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(tabletPFH) = -1;
};
[] call EFUNC(tacpad,setHost);

// VEHICLE STATUS leaves with the vehicle tablet (FUNC(onLoad)): no other host
// may open it. Its refresh loop stops itself on its next tick.
//
// AND IT STOPS BEING THE OPEN APP. The shell's close leaves appCurrent alone,
// and the native map's next open reopens whatever it names - every panel built
// hidden behind it and the tick held - while openApp refuses an app with no
// handler. Other apps keep their handlers, so only this one can be stranded.
if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo VEHICLE_APP) then {
    uiNamespace setVariable [QEGVAR(tacpad,appCurrent), ""];
};
EGVAR(tacpad,appHandlers) deleteAt VEHICLE_APP;

uiNamespace setVariable [QGVAR(display), displayNull];
