#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes one order from the support page and either sends it to the server or
 * says why not - the "task" code of provider "fires".
 *
 * EVERY REFUSAL A MAN CAN FIX IS SAID HERE, before anything leaves his
 * machine - Simplex's request checks: no target point, inside the minimum or
 * beyond the maximum range, nothing of that type left. The server re-checks
 * only what can change in flight (a race with a second caller) and acks the
 * result (EFUNC(support,ack)).
 *
 * THE STEPPER SLOTS ARE READ BY FUNC(readOpts) AND TRAVEL AS VALUES - the same
 * reading the verdict before CONFIRM (FUNC(preview)) describes. The range is
 * FUNC(inRange), for every asset type.
 *
 * RTB: a battery checks fire (with every battery that joined it), loitering
 * munitions self-destruct; a cruise missile in flight cannot be recalled.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Task token <STRING>
 * 2: Target position <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, "" when accepted <STRING>
 *
 * Example:
 * ["fires:0", "FFE", [1000, 2000, 0], []] call jmfsb_support_fires_fnc_task
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "that asset is gone"]};

private _type = _logic getVariable [QGVAR(type), ""];
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];

if (_task isEqualTo TASK_RTB) exitWith {
    switch (true) do {
        case (_type isEqualTo TYPE_CRUISE): {
            [false, format ["%1: missiles in flight cannot be recalled", _callsign]]
        };
        case ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE): {
            [false, format ["%1 is not on a mission", _callsign]]
        };
        default {
            [QGVAR(abort), [_logic]] call CBA_fnc_serverEvent;
            [true, ""]
        };
    }
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, _why]};

if (_pos isEqualTo []) exitWith {[false, "no target point"]};

private _target = [_pos select 0, _pos select 1, 0];
private _opts = [_logic, _prm] call FUNC(readOpts);
if (_opts isEqualTo []) exitWith {[false, format ["%1 has nothing left to fire", _callsign]]};

private _range = [_logic, _target] call FUNC(inRange);
if (_range isNotEqualTo "") exitWith {[false, format ["%1: %2", _callsign, _range]]};

// THE SERVER FIRES. A client that spawned its own rounds would own shells
// nobody else could see land.
[QGVAR(request), [_logic, _target, _opts, player]] call CBA_fnc_serverEvent;

[true, ""]
