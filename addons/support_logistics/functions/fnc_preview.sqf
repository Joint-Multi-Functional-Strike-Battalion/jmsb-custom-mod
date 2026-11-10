#include "script_component.hpp"
/*
 * Author: YonV
 * The verdict before CONFIRM - the "preview" code of provider "logi"
 * (support core README). Asked on every redraw of the board with exactly the
 * parameters CONFIRM would send, so it runs the same check the order will
 * (FUNC(check)) and changes nothing:
 *
 *   "ETA 4 MIN - 2 x HUNTER, 1 x CRATE - MAGAZINES (3/4) - LAST AIRFRAME"
 *
 * FALSE FOR WHATEVER THE ORDER WOULD BE REFUSED FOR, with its reason: busy,
 * turning round, spent, a method it does not fly, nothing ordered, over the
 * capacity, an item the hook cannot take.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: Task token <STRING>
 * 2: Delivery point, [] for none <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: The order would be accepted <BOOL>
 * 1: The verdict line <STRING>
 *
 * Example:
 * ["logi:0", "AIRDROP", [1000, 2000, 0], []] call jmfsb_support_logistics_fnc_preview
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "THAT ASSET IS GONE"]};

([_logic, _task, _pos, _prm, player] call FUNC(check)) params ["_ok", "_why", "_at", "_cart"];
if (!_ok) exitWith {[false, toUpper _why]};
if (_task isEqualTo TASK_RTB) exitWith {[true, "RECALL"]};

private _names = [_logic getVariable [QGVAR(catalog), []], _cart] call FUNC(cartNames);
private _cap = _logic getVariable [QGVAR(capacity), DEF_CAPACITY];
private _eta = [_logic, _at] call FUNC(eta);
private _left = _logic getVariable [QGVAR(left), -1];

private _line = format ["%1 (%2/%3)", [_names] call FUNC(countLine), count _names, _cap];
if (_eta >= 0) then {_line = format ["ETA %1 - %2", [_eta] call EFUNC(cas,fmtEta), _line]};
if (_left >= 0) then {
    _line = _line + REACH_SEP + format [SPARE_WORDS select ((count SPARE_WORDS - 1) - (_left min (count SPARE_WORDS - 1))), _left];
};

[true, _line]
