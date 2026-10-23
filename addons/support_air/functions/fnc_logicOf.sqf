#include "script_component.hpp"
/*
 * Author: JMSB
 * The module behind an asset id - "air:<n>" is entity n.
 *
 * Arguments:
 * 0: Asset id <STRING>
 *
 * Return Value:
 * The module logic, objNull when there is none <OBJECT>
 *
 * Example:
 * ["air:0"] call jmfsb_support_air_fnc_logicOf
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _parts = _assetId splitString ":";
if ((_parts param [0, ""]) isNotEqualTo SUPPORT_KIND) exitWith {objNull};

private _n = parseNumber (_parts param [1, "-1"]);
private _logic = (missionNamespace getVariable [QGVAR(entities), []]) param [_n, objNull];
if !(_logic isEqualType objNull) exitWith {objNull};

_logic
