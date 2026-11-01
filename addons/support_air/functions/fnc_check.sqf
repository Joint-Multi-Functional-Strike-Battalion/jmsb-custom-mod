#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether one order may go to this asset, and the point it is flown to - the
 * ONE check the requester's machine (FUNC(task)) and the server
 * (FUNC(order)) both run. The server runs it again with the sender's own
 * unit, because a client can call the server without passing FUNC(task)
 * (review S6).
 *
 * NO GRID IS ALLOWED ONLY WHERE "ON ME" MAKES SENSE. A PICKUP or an EXTRACT
 * without a point comes to the requester; everything else is aimed at a
 * place and the screen already holds CONFIRM until one is set.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: The requester <OBJECT>
 *
 * Return Value:
 * 0: May be flown <BOOL>
 * 1: Why not, "" when it may <STRING>
 * 2: The point to fly to, [x, y, 0], [] for a recall <ARRAY>
 *
 * Example:
 * [_logic, "SAD", _pos, [], player] call jmfsb_support_air_fnc_check
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_unit", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "that asset is gone", []]};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _kind = _logic getVariable [QGVAR(kind), ""];

// The side's own assets only - the board lists no other (FUNC(assets)), but
// a request can come from anywhere.
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group _unit)) exitWith {
    [false, format ["%1 is not your side's asset", _callsign], []]
};

// RECALL IS PASSED THROUGH WHENEVER SOMETHING IS OUT - an asset you want home
// is busy. Idle covers turning round and spent too - nothing is out to recall.
if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {
        [false, format ["%1 is at base - nothing to recall", _callsign], []]
    };
    [true, "", []]
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, _why, []]};

// The token must be one THIS asset offers - the screen only shows those, but
// a request can come from anywhere.
private _offered = ([format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], [_logic] call FUNC(entityRow)] call FUNC(tasks)) apply {_x select 0};
if !(_task in _offered) exitWith {
    INFO_3("check: refused for %1 - '%2' is not one of %3",_callsign,_task,_offered);
    [false, format ["%1 does not fly %2", _callsign, _task], []]
};

if (_pos isEqualTo [] && {_task in [TASK_PICKUP, TASK_EXTRACT, TASK_LIFT]}) then {_pos = getPosATL _unit};
if (_pos isEqualTo []) exitWith {[false, "no target grid", []]};
_pos = [_pos param [0, 0, [0]], _pos param [1, 0, [0]], 0];

if (_task in [TASK_LIFT, TASK_SLING] && {([_prm, SLOT_LZ] call FUNC(readPoint)) isEqualTo []}) exitWith {
    [false, format ["%1 needs %2", _task, ["an LZ", "a set-down point"] select (_task isEqualTo TASK_SLING)], []]
};
if (_task isEqualTo TASK_HELOCAST && {!surfaceIsWater _pos}) exitWith {
    [false, format ["%1 casts over water only - %2 is land", _callsign, mapGridPosition _pos], []]
};

// The QRF squad must exist before the aircraft is sent for it.
if (_kind isEqualTo KIND_QRF && {([_logic] call FUNC(qrfSquad)) isEqualTo []}) exitWith {
    [false, format ["%1 has no squad to send", _callsign], []]
};

[true, "", _pos]
