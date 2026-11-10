#include "script_component.hpp"
/*
 * Author: YonV
 * Client: a recorded target's marker (RECORD AS TARGET, user 2026-11-02;
 * FUNC(record)) is its battery's side's alone - on a machine whose player is
 * of another side it is hidden here. The server made it global, so the card
 * reader finds it by name; it reaches this machine on its own, maybe after
 * this call (a JIP), so this waits for it, at most TARGET_WAIT s. By
 * remoteExec from the server only (review S7).
 *
 * Arguments:
 * 0: The marker's name <STRING>
 * 1: Its battery's side <SIDE>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TH1001", west] call jmfsb_support_fires_fnc_targetLocal
 *
 * Public: No
 */

params [["_name", "", [""]], ["_side", sideUnknown, [sideUnknown]]];

if (!hasInterface || _name isEqualTo "") exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("targetLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

[{
    params ["_name"];
    !isNull player && markerShape _name isNotEqualTo ""
}, {
    params ["_name", "_side"];
    if ((side group player) isNotEqualTo _side) then {_name setMarkerAlphaLocal 0};
}, [_name, _side], TARGET_WAIT] call CBA_fnc_waitUntilAndExecute;
