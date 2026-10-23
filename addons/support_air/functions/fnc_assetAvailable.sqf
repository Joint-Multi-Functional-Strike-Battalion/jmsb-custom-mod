#include "script_component.hpp"
/*
 * Author: JMSB
 * FUNC(available) by asset id - the "available" code this provider hands the
 * support core, asked before anything but a recall.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 *
 * Return Value:
 * 0: Can be tasked now <BOOL>
 * 1: Why not, "" when it can <STRING>
 *
 * Example:
 * ["air:0"] call jmfsb_support_air_fnc_assetAvailable
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

([[_assetId] call FUNC(logicOf)] call FUNC(available)) params ["_ok", "", "_why"];

[_ok, _why]
