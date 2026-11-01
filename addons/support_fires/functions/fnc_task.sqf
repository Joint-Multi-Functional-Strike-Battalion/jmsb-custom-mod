#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes one order from the support page and either sends it to the server or
 * says why not - the "task" code of provider "fires".
 *
 * EVERY REFUSAL A MAN CAN FIX IS SAID HERE, before anything leaves his
 * machine - FUNC(check): no target point, inside the minimum or beyond the
 * maximum range, nothing of that type left. The order goes to the server by
 * remoteExec (FUNC(request), FUNC(abort)), which knows who sent it and runs
 * the same check again for him (review S6) - a CBA event would not tell it.
 *
 * THE STEPPER SLOTS TRAVEL AS THE PARAMETER ARRAY, and FUNC(readOpts) reads
 * them on both ends - the same reading the verdict before CONFIRM
 * (FUNC(preview)) describes. The range is FUNC(inRange), for every asset
 * type.
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

([_logic, _task, _pos, _prm, player] call FUNC(check)) params ["_ok", "_why", "_target"];
if (!_ok) exitWith {[false, _why]};

if (_task isEqualTo TASK_RTB) exitWith {
    [_logic] remoteExecCall [QFUNC(abort), SERVER_OWNER];
    [true, ""]
};

// THE SERVER FIRES. A client that spawned its own rounds would own shells
// nobody else could see land.
[_logic, _target, +_prm] remoteExecCall [QFUNC(request), SERVER_OWNER];

[true, ""]
