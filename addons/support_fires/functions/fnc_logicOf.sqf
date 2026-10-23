#include "script_component.hpp"
/*
 * Author: JMSB
 * The module logic behind an asset id "fires:<n>".
 *
 * Arguments:
 * 0: Asset id <STRING>
 *
 * Return Value:
 * The module logic, objNull when there is none <OBJECT>
 *
 * Example:
 * ["fires:0"] call jmfsb_support_fires_fnc_logicOf
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _n = parseNumber ((_assetId splitString ":") param [1, "-1"]);
if (_n < 0) exitWith {objNull};

GVAR(entities) param [_n, objNull]
