#include "script_component.hpp"
/*
 * Author: JMSB
 * The decline key - Ctrl + numpad 6 in the numpad standard (user, 2026-10-24:
 * the F-keys no longer answer or decline). Closes the quick-add list if it is
 * open; else declines the call that is ringing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Acted <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_voiceDeclineKey
 *
 * Public: No
 */

if (GVAR(quickOpen)) exitWith {
    GVAR(quickOpen) = false;
    true
};
if (isNil QEFUNC(voice,calls) || {isNil QEFUNC(voice,callDecline)}) exitWith {false};

private _ring = ([] call EFUNC(voice,calls)) select {(_x param [1, ""]) isEqualTo CALL_RINGING};
if (_ring isEqualTo []) exitWith {false};

[(_ring select 0) select 0] call EFUNC(voice,callDecline);
true
