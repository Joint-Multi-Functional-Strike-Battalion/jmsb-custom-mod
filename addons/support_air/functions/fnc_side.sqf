#include "script_component.hpp"
/*
 * Author: YonV
 * Whose aircraft an asset id is - the "side" code this addon hands the
 * support core, which asks it on the server before a thread filed to the
 * aircraft's box is the aircraft's (2026-11-01). The module's side, as
 * FUNC(check) reads it.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 *
 * Return Value:
 * The side, sideUnknown when there is no such asset <SIDE>
 *
 * Example:
 * ["air:0"] call jmfsb_support_air_fnc_side
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {sideUnknown};

_logic getVariable [QGVAR(side), sideUnknown]
