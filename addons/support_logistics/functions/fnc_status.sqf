#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the support core's "status" hook (2026-11-09, STATUS in a
 * logistics thread - EFUNC(support,statusReply)): the delivery aircraft (the
 * core reads its grid, fuel and pax), and what it is doing - the module's
 * status and the job's step.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 *
 * Return Value:
 * [vehicle, task text, minutes left on station (-1)] <ARRAY>
 *
 * Example:
 * ["logi:0", "T0042"] call jmfsb_support_logistics_fnc_status
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[objNull, "", -1]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];
private _words = [[toUpper _status, toUpper _why] select (_why isNotEqualTo "")];
private _step = (_logic getVariable [QGVAR(threadJob), createHashMap]) getOrDefault ["step", ""];
if (_step isNotEqualTo "") then {_words pushBack (toUpper _step)};

[_logic getVariable [QGVAR(vehicle), objNull], _words joinString WILCO_SEP, -1]
