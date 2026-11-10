#include "script_component.hpp"
/*
 * Author: YonV
 * The verdict before CONFIRM - the "preview" code of provider "cas" (support
 * core README). Asked on every redraw of the board with exactly the
 * parameters CONFIRM would send, so it reads only what the server published
 * on the module, changes nothing and walks nothing.
 *
 * THE TIME IS THE RUN FUNC(launch) WILL FLY (user, 2026-11-02: virtual until
 * tasked, made over the module): from the module - by the INGRESS point when
 * one is set - at the module's speed, capped at what the airframe can do.
 *
 *   strike  "ETA 1 MIN 50 S - 2 RESPAWNS LEFT"
 *   loiter  "ON STATION IN 1 MIN 50 S - LAST AIRFRAME"
 *
 * FALSE ONLY FOR WHAT FUNC(task) WOULD REFUSE: the asset gone, busy, cooling
 * down or waiting for a replacement (FUNC(available)), or no target grid.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Task token <STRING>
 * 2: Target position <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: The order would be accepted <BOOL>
 * 1: The verdict line <STRING>
 *
 * Example:
 * ["cas:0", "ATTACK RUN", [1000, 2000, 0], []] call jmfsb_cas_fnc_preview
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[false, "THAT ASSET IS GONE"]};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, toUpper _why]};
if (_pos isEqualTo []) exitWith {[false, "NO TARGET GRID"]};

private _ingress = _prm param [8, []];
if !(_ingress isEqualType []) then {_ingress = []};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _speed = ((_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) min getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed")) / KMH_PER_MS;
private _eta = 0;
private _dist = _logic distance2D _pos;
if (count _ingress >= 2) then {_dist = (_logic distance2D _ingress) + (_ingress distance2D _pos)};
if (_speed > 0) then {_eta = _dist / _speed};

private _line = format [
    ["ETA %1", "ON STATION IN %1"] select (toUpper _task isEqualTo "LOITER"),
    [_eta] call FUNC(fmtEta)
];

// What is left (the respawn count, user 2026-11-02).
private _left = _logic getVariable [QGVAR(respawnsLeft), MODULE_RESPAWNS];
_line = _line + " - " + ([format [LEFT_RESPAWNS, _left], LEFT_LAST] select (_left <= 0));

[true, _line]
