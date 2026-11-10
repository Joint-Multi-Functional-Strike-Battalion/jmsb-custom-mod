#include "script_component.hpp"
/*
 * Author: YonV
 * Server: RTB for one CAS asset, sent by remoteExec from FUNC(task). Only a
 * man of the asset's own side who may task support recalls it (review S6:
 * a CBA server event let any client abort any side's run). FUNC(mayTask)
 * checks the real sender.
 *
 * Recall is a flag rather than a direct delete: the run watch owns the
 * aircraft's life, and two things deleting one airframe is how a
 * <NULL-object> ends up in a ledger.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] remoteExecCall ["jmfsb_cas_fnc_abort", 2]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer) exitWith {};

([_logic] call FUNC(mayTask)) params ["_ok", "", "_why"];
if (!_ok) exitWith {
    WARNING_2("abort: refused from machine %1 - %2",remoteExecutedOwner,_why);
};

// No run, nothing to recall. A flag raised on an asset between runs - ready,
// cooling down, replacing, expended - would sit there and kill the next run on
// its first tick.
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) in STATUSES_NO_RUN) exitWith {};
_logic setVariable [QGVAR(abort), true, true];
