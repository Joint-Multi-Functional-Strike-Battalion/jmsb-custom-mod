#include "script_component.hpp"
/*
 * Author: YonV
 * FUNC(available) by asset id - the "available" code this provider hands the
 * support core, asked before anything but a recall.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 *
 * Return Value:
 * 0: Can be tasked now <BOOL>
 * 1: Why not, "" when it can <STRING>
 *
 * Example:
 * ["logi:0"] call jmfsb_support_logistics_fnc_assetAvailable
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

([[_assetId] call FUNC(logicOf)] call FUNC(available)) params ["_ok", "", "_why"];

[_ok, _why]
