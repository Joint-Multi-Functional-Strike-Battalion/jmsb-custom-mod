#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the ALT readout (FUNC(altCell)) at the front of the phone's status
 * row for a jump and takes it out again on the ground. jmfsb_devices shows
 * the first OVERLAY_STATUS_CELLS of its order and six are named already, so
 * ALT leads only while it has something to say. Started by FUNC(jump) for
 * the local player; the watch stops itself when he is down - on the ground
 * out of any vehicle, or dead.
 *
 * Arguments:
 * 0: On <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call jmfsb_jumpmaster_fnc_altWatch
 *
 * Public: No
 */

params [["_on", true, [true]]];

private _order = (missionNamespace getVariable [QEGVAR(devices,overlayOrder), []]) - [ALT_ICON];
if (_on) then {_order = [ALT_ICON] + _order};
missionNamespace setVariable [QEGVAR(devices,overlayOrder), _order];

if (!_on) exitWith {};

private _pfh = uiNamespace getVariable [QGVAR(altPfh), -1];
if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
uiNamespace setVariable [QGVAR(altPfh), [{
    params ["", "_handle"];
    private _me = call CBA_fnc_currentUnit;
    private _down = isNull _me || {!alive _me} || {
        isNull objectParent _me && {isTouchingGround _me || {((getPosATL _me) select 2) < ALT_DOWN_M}}
    };
    if (!_down) exitWith {};
    [_handle] call CBA_fnc_removePerFrameHandler;
    uiNamespace setVariable [QGVAR(altPfh), -1];
    [false] call FUNC(altWatch);
}, ALT_WATCH_S, []] call CBA_fnc_addPerFrameHandler];
