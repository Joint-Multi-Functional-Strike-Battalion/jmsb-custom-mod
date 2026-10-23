#include "script_component.hpp"
/*
 * Author: JMSB
 * FUNC(available) by asset id - the "available" code this addon hands the
 * support core, which asks it before dispatching anything but a recall.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 *
 * Return Value:
 * 0: Can be tasked right now <BOOL>
 * 1: Why not, "" when it can <STRING>
 *
 * Example:
 * ["cas:0"] call jmfsb_cas_fnc_assetAvailable
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
([_logic] call FUNC(available)) params ["_ok", "", "_why"];

[_ok, _why]
