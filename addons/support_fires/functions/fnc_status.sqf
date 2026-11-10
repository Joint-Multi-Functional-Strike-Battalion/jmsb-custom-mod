#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the support core's "status" hook (2026-11-09, STATUS in a battery's
 * thread - EFUNC(support,statusReply)). A battery or launcher has no one
 * aircraft to read a grid, fuel and pax off, so no vehicle is given: the task
 * says what it is doing, on which point, and what it has left.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * [vehicle (objNull), task text, minutes left on station (-1)] <ARRAY>
 *
 * Example:
 * ["fires:0", "T0042"] call jmfsb_support_fires_fnc_status
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[objNull, "", -1]};

private _words = [toUpper (_logic getVariable [QGVAR(status), STATUS_IDLE])];
private _target = (_logic getVariable [QGVAR(threadOrder), createHashMap]) getOrDefault ["target", []];
if (_target isNotEqualTo []) then {_words pushBack (mapGridPosition _target)};
_words pushBack ([_logic] call FUNC(stockWords));

[objNull, _words joinString WILCO_SEP, -1]
