#include "script_component.hpp"
/*
 * Author: YonV
 * FUNC(available) by asset id - the "available" code this addon hands the
 * support core, which asks it before dispatching anything but a recall. A
 * battery holding an adjust mission answers yes to the player it holds for.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 *
 * Return Value:
 * 0: Can be tasked right now <BOOL>
 * 1: Why not, "" when it can <STRING>
 *
 * Example:
 * ["fires:0"] call jmfsb_support_fires_fnc_assetAvailable
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
([_logic] call FUNC(available)) params ["_ok", "", "_why"];

// ADJUST FIRE (2026-11-01): a battery holding an adjust mission for this
// player takes his next call; FUNC(check) then says which calls.
if (!_ok && hasInterface) then {
    if ((_logic getVariable [QGVAR(holdBy), ""]) isEqualTo getPlayerUID player) then {
        _ok = true;
        _why = "";
    };
};

[_ok, _why]
