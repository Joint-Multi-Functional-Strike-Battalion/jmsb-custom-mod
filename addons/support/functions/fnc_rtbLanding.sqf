#include "script_component.hpp"
/*
 * Author: YonV
 * Where an aircraft going home lands first to let its players off (user,
 * 2026-11-09: "we need a way to set an rtb landing location if an aircraft
 * has players on board"): the RTB card's LAND AT point (RTB_CARDS), when the
 * reply is an RTB that gives one and a live player rides in the aircraft
 * outside its crew seats. The providers that carry men (support_air's
 * Transport and QRF, the jumpmaster) ask this on WORD_STOP and fly there,
 * land, wait for the players to get out, then go home; [] - home as before.
 *
 * Arguments:
 * 0: The reply that stopped it <HASHMAP>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * The landing point, [] for none <ARRAY>
 *
 * Example:
 * private _land = [_message, _veh] call jmfsb_support_fnc_rtbLanding
 *
 * Public: Yes
 */

params [["_message", createHashMap, [createHashMap]], ["_veh", objNull, [objNull]]];

if (!alive _veh) exitWith {[]};
if ((RTB_CARDS findIf {(_x select 0) isEqualTo (_message getOrDefault ["templateId", ""])}) < 0) exitWith {[]};

// A passenger: a cargo seat, or a firing-from-vehicle seat (a person turret)
// - never a door gunner's or a pilot's.
private _players = (fullCrew [_veh, "", false]) select {
    _x params ["_unit", "_role", "", "", ["_personTurret", false]];
    isPlayer _unit && {alive _unit} && {_role isEqualTo "cargo" || {_role isEqualTo "turret" && _personTurret}}
};
if (_players isEqualTo []) exitWith {[]};

private _order = [createHashMap, _message] call FUNC(readOrder);
_order getOrDefault ["land", []]
