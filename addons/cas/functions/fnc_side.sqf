#include "script_component.hpp"
/*
 * Author: YonV
 * Whose drone an asset id is - the "side" code this addon hands the support
 * core, which asks it on the server before a thread filed to the drone's box
 * is the drone's (2026-11-01). The module's side, as FUNC(mayTask) reads it.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 *
 * Return Value:
 * The side, sideUnknown when there is no such asset <SIDE>
 *
 * Example:
 * ["cas:0"] call jmfsb_cas_fnc_side
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {sideUnknown};

_logic getVariable [QGVAR(side), sideUnknown]
