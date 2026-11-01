#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes one order from TAC//SUPPORT and either sends it to the server or
 * says why not - the "task" code of provider "air".
 *
 * RUNS ON THE REQUESTER'S MACHINE (the core calls it there). Everything that
 * can be refused is refused here (FUNC(check)), with the reason on his
 * screen; what is accepted is flown on the server, which owns every aircraft
 * this addon creates. It goes there by remoteExec to FUNC(order), which runs
 * the same check again with the sender's own unit (review S6) - a CBA event
 * would not tell the server who sent it.
 *
 * THE COOLDOWN IS THIS ADDON'S, NOT THE CORE'S. An air asset is turned round
 * when the aircraft is home, not when the order is given, so the module
 * starts its own clock at the end of the sortie (FUNC(finish)) and this
 * returns no cooldown to the core.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, or what was sent <STRING>
 * 2: Core cooldown, always 0 <NUMBER>
 *
 * Example:
 * ["air:0", "SAD", getPosATL player, []] call jmfsb_support_air_fnc_task
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {
    WARNING_1("task: no asset behind id '%1'",_assetId);
    [false, "that asset is gone", 0]
};

([_logic, _task, _pos, _prm, player] call FUNC(check)) params ["_ok", "_why", "_at"];
if (!_ok) exitWith {[false, _why, 0]};

[_logic, _task, _at, +_prm] remoteExecCall [QFUNC(order), SERVER_OWNER];

if (_task isEqualTo TASK_RTB) exitWith {
    private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
    INFO_1("%1 recalled",_callsign);
    [true, format ["%1 returning to base", _callsign], 0]
};

[true, "", 0]
