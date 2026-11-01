#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether one order may go to this asset, and what it fires - the ONE check
 * the requester's machine (FUNC(task)) and the server (FUNC(request),
 * FUNC(abort)) both run. The server runs it again with the sender's own
 * unit, because a client can call the server without passing FUNC(task)
 * (review S6), and builds the options from the parameter array itself
 * rather than taking them from the client.
 *
 * Simplex's request checks: the side's own asset, no target point, inside
 * the minimum or beyond the maximum range (FUNC(inRange)), nothing of that
 * type left. RTB: a cruise missile in flight cannot be recalled, and an idle
 * asset has nothing to recall.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position, [] for none <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 * 4: The requester <OBJECT>
 *
 * Return Value:
 * 0: May be fired <BOOL>
 * 1: Why not, "" when it may <STRING>
 * 2: Target, [x, y, 0], [] for a recall <ARRAY>
 * 3: Options for the type (FUNC(readOpts)), [] for a recall <ARRAY>
 *
 * Example:
 * [_logic, "FFE", _pos, [], player] call jmfsb_support_fires_fnc_check
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_unit", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "that asset is gone", [], []]};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];

// The side's own assets only - the page lists no other (FUNC(assets)), but a
// request can come from anywhere.
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group _unit)) exitWith {
    [false, format ["%1 is not your side's asset", _callsign], [], []]
};

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(type), ""]) isEqualTo TYPE_CRUISE) exitWith {
        [false, format ["%1: missiles in flight cannot be recalled", _callsign], [], []]
    };
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {
        [false, format ["%1 is not on a mission", _callsign], [], []]
    };
    [true, "", [], []]
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, _why, [], []]};

if (_pos isEqualTo []) exitWith {[false, "no target point", [], []]};
private _target = [_pos param [0, 0, [0]], _pos param [1, 0, [0]], 0];

private _opts = [_logic, _prm] call FUNC(readOpts);
if (_opts isEqualTo []) exitWith {[false, format ["%1 has nothing left to fire", _callsign], [], []]};

private _range = [_logic, _target] call FUNC(inRange);
if (_range isNotEqualTo "") exitWith {[false, format ["%1: %2", _callsign, _range], [], []]};

[true, "", _target, _opts]
