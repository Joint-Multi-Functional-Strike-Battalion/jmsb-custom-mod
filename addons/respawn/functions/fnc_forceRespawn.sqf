#include "script_component.hpp"
/*
 * Author: YonV (from veteran29's module)
 * Forces the dead players of a side back into the fight.
 *
 * WAS A MODULE, IS A FUNCTION. Forcing a respawn is trigger-fired and one-shot -
 * it answers "when", not "where" - so under the four-class config rule it has no
 * business being a placeable module. A trigger's On Activation field is where a
 * mission maker was already going to express "now", and this is one line in it:
 *
 *     [west] call jmfsb_respawn_fnc_forceRespawn;
 *
 * Only the DEAD are respawned. A living player is not interrupted, which is the
 * whole reason this is safe to fire from a trigger that may run more than once.
 *
 * OFF THE SERVER the filter runs here and only the men it picked are sent, by
 * remoteExec, to FUNC(forceRespawnRequest) - the server never runs code a
 * client sent, and takes the request only from an admin or a Zeus (review S7).
 *
 * Arguments:
 * 0: Side to respawn, sideUnknown for every side <SIDE> (optional)
 * 1: Filter - code taking [unit], returning whether to respawn them <CODE>
 *    (optional, default everyone)
 *
 * Return Value:
 * How many were respawned, 0 off the server <NUMBER>
 *
 * Example:
 * [west, {alive (leader group (_this select 0))}] call jmfsb_respawn_fnc_forceRespawn
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]], ["_filter", {true}, [{}]]];

private _units = allPlayers select {
    !alive _x
    && {_side isEqualTo sideUnknown || {side group _x isEqualTo _side}}
    && {[_x] call _filter}
};

if (!isServer) exitWith {
    if (_units isNotEqualTo []) then {
        [_units] remoteExecCall [QFUNC(forceRespawnRequest), SERVER_OWNER];
    };
    0
};

if (_units isEqualTo []) exitWith {0};

INFO_2("Respawning %2 dead player(s) of side %1:",_side,count _units);
{
    diag_log text format ["    %1", name _x];
} forEach _units;

[] remoteExecCall [QFUNC(forceLocal), _units];

count _units
