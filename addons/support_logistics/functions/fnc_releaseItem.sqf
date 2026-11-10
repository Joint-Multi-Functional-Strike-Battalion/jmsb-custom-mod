#include "script_component.hpp"
/*
 * Author: YonV
 * One airdropped item leaves the aircraft: made just behind and below the
 * tail (FUNC(spawnItem)), carrying the aircraft's own velocity, under a
 * cargo chute with its landing watch (EFUNC(common,addParachuteToObject)),
 * and marked once it is down (FUNC(markItem)).
 *
 * WHEN THE CHUTE OPENS is the module's Chute Opens At: -1 at once, otherwise
 * the item falls free until it is that low - Simplex's opening altitude for
 * objects. Only what the engine simulates falls (vehicles and physics
 * objects); anything else would hang in the air where it was made, so it
 * opens at once whatever the module says.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The catalog item <ARRAY>
 * 3: Marking class, "" for none <STRING>
 *
 * Return Value:
 * The item, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [_logic, _veh, _entry, "SmokeShellBlue"] call jmfsb_support_logistics_fnc_releaseItem
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_entry", [], [[]]], ["_signal", "", [""]]];

// Made first, out of the way: its size is known once it exists.
private _item = [_logic, _entry, [0, 0, 0], getDir _veh] call FUNC(spawnItem);
if (isNull _item) exitWith {objNull};
private _behind = (sizeOf typeOf _veh) / 2 + (sizeOf typeOf _item) / 2 + TAIL_GAP;
_item setPosASL (_veh modelToWorldWorld [0, -_behind, -BELLY_GAP]);

private _vel = velocity _veh;
private _open = _logic getVariable [QGVAR(openHeight), DEF_OPEN_HEIGHT];
private _falls = (FREEFALL_KINDS findIf {_item isKindOf _x}) > -1;

if (_open < 0 || !_falls) then {
    // The item rides attached under the chute, so the aircraft's momentum
    // goes on the chute - a chute made at rest drops it short of the point.
    private _chute = [_item] call EFUNC(common,addParachuteToObject);
    _chute setVelocity _vel;
} else {
    _item setVelocity _vel;
    [
        {
            params ["_item", "_open"];
            isNull _item || {((getPos _item) select 2) < _open}
        },
        {
            params ["_item"];
            if (isNull _item) exitWith {};
            private _v = velocity _item;
            private _chute = [_item] call EFUNC(common,addParachuteToObject);
            _chute setVelocity _v;
        },
        [_item, _open],
        FREEFALL_PATIENCE
    ] call CBA_fnc_waitUntilAndExecute;
};

[_item, _signal] call FUNC(markItem);

_item
