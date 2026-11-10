#include "script_component.hpp"
/*
 * Author: YonV
 * Deletes one of this player's own ALiVE Advanced Markers, the way ALiVE
 * deletes it: off every map on its locality and out of ALiVE's store (and its
 * database on a dedicated server). For jmfsb_maptools: a MAP TOOLS MARK press
 * on a marker deletes it when it is his (user, 2026-11-01). Client side.
 *
 * HIS OWN ONLY. ALiVE keeps the placer's Steam id with each marker; its own
 * check lets anyone delete anything, which is more than a press on a tablet
 * should do.
 *
 * Arguments:
 * 0: Marker <STRING>
 *
 * Return Value:
 * It was his ALiVE marker and is deleted <BOOL>
 *
 * Example:
 * [_marker] call jmfsb_adapter_alive_fnc_markerRemove
 *
 * Public: Yes
 */

// The owner's key in an ALiVE marker's hash (sys_marker's GVAR(player)).
#define ALIVE_MARKER_OWNER "ALiVE_SYS_marker_player"

params [["_marker", "", [""]]];

if (_marker isEqualTo "") exitWith {false};
if (isNil "ALiVE_SYS_marker") exitWith {false};
if (isNil "ALiVE_SYS_marker_STORE") exitWith {false};
if !(_marker in (ALiVE_SYS_marker_STORE select 1)) exitWith {false};

private _hash = [ALiVE_SYS_marker_STORE, _marker] call ALiVE_fnc_hashGet;
if (([_hash, ALIVE_MARKER_OWNER, ""] call ALiVE_fnc_hashGet) isNotEqualTo getPlayerUID player) exitWith {false};

[ALiVE_SYS_marker, "removeMarker", [_marker]] call ALiVE_fnc_marker;

true
