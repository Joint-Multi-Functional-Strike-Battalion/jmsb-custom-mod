#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a hack started on a tablet (FUNC(tabletAction), by remoteExec). The
 * server checks the sender may hack that device (FUNC(srvMayHack)) and starts
 * its own clock on it, so a completion can be held to the kind's time
 * (FUNC(srvHackComplete), review S7). The earliest start on a device is kept
 * until a hack of it completes: a closed tablet pauses a hack, it does not
 * restart it, and a second operator can finish what the first began. A start
 * on a leaders' internet pop is checked for civilian witnesses here
 * (FUNC(popWitness)).
 *
 * Arguments:
 * 0: The device <OBJECT>
 * 1: Kind, "tower" | "drone" | "wreck" | "unit" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_device, "tower"] remoteExecCall ["jmfsb_hacking_fnc_srvHackStart", 2]
 *
 * Public: No
 */

params [["_device", objNull, [objNull]], ["_kind", "", [""]]];

if (!isServer) exitWith {};

// The operator is the machine that sent this, never a unit from the request.
([] call EFUNC(common,sender)) params ["_owner", "_unit"];

private _why = [_unit, _device, _kind] call FUNC(srvMayHack);
if (_why isNotEqualTo "") exitWith {
    WARNING_3("srvHackStart: %1 refused on %2 - %3",_unit,_device,_why);
};

// A pop is public furniture - being seen starting on one has a price, decided
// here for the checked sender (review S7).
if (_device getVariable [QEGVAR(leaders,pop), false]) then {
    [_unit, _device, _owner] call FUNC(popWitness);
};

private _starts = localNamespace getVariable [QGVAR(srvStarts), createHashMap];
private _key = _device call BIS_fnc_netId;
if !(_key in _starts) then {
    _starts set [_key, CBA_missionTime];
};
localNamespace setVariable [QGVAR(srvStarts), _starts];
TRACE_3("srvHackStart",_unit,_device,_kind);
