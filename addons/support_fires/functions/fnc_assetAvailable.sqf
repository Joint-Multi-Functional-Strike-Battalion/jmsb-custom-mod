#include "script_component.hpp"
/*
 * Author: JMSB
 * FUNC(available) by asset id - the "available" code this addon hands the
 * support core, which asks it before dispatching anything but a recall.
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

([[_assetId] call FUNC(logicOf)] call FUNC(available)) params ["_ok", "", "_why"];

[_ok, _why]
