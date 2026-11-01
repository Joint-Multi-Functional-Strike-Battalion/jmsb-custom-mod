#include "script_component.hpp"
/*
 * Author: JMSB
 * The call camera key (user, 2026-10-28: "the flip needs a key bind"): flips
 * what the player's camera sends on his live call, FACE or VIEW
 * (jmfsb_tacpad_apps_fnc_callCamFlip), and redraws the labels that name it -
 * the walking view's RADIO soft key and the tablet's RADIO page. Not handled
 * with no live call, so the key falls through.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_voiceCamKey
 *
 * Public: No
 */

if (isNil QEFUNC(tacpad_apps,callFeedUnit) || {([] call EFUNC(tacpad_apps,callFeedUnit)) isEqualTo []}) exitWith {false};

[] call EFUNC(tacpad_apps,callCamFlip);
if (GVAR(radioOpen)) then {[] call FUNC(overlayTick)};
if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo "radio") then {
    ["radio"] call EFUNC(tacpad,openApp);
};
true
