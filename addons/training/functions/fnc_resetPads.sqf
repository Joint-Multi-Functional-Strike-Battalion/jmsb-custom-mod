#include "..\script_component.hpp"
/*
 * Author: YonV
 * Server: replaces every target on a controller's pads that is damaged or
 * gone (FUNC(targetPads)). The new one comes after PAD_RESPAWN_DELAY, so
 * the wreck is cleared first.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_ctrl", objNull, [objNull]]];

if (!isServer || {isNull _ctrl}) exitWith {};

(_ctrl getVariable [QGVAR(pads), [[], []]]) params ["_pads", "_classes"];

{
    private _pad = [_x] call FUNC(resolve);
    if (!isNull _pad) then {
        private _type = _classes select _forEachIndex;
        private _near = nearestObjects [_pad, [_type], PAD_RADIUS];
        if (_near isEqualTo [] || {damage (_near select 0) > 0}) then {
            {deleteVehicle _x} forEach _near;
            [FUNC(spawnPadTarget), [_type, _pad], PAD_RESPAWN_DELAY] call CBA_fnc_waitAndExecute;
        };
    };
} forEach _pads;
