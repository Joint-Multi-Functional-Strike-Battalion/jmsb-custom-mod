#include "script_component.hpp"
/*
 * Author: YonV
 * The "reach" code of provider "cas" (support core README, 2026-11-01):
 * whether this drone module can put an airframe over one map point, how soon
 * and with what - its row of the board's reach card. Asked once per target
 * click on the viewer's machine, so it reads only what the server published
 * on the module, the way the verdict before CONFIRM (FUNC(preview)) does.
 *
 * THE ETA (user, 2026-11-02: "all support aircraft needs to be virtual till
 * tasked, then they spawn in at alt over the support module location"): from
 * the module to the point at the module's speed, capped at what the airframe
 * can do. Unknown (-1) when the class has no top speed to fly it by.
 *
 * Every task is valid at any point (the module has no range): SAD, LOITER and
 * ATTACK RUN. The effect is the airframe's stores (FUNC(stores)) and the
 * respawns left (the respawn count, user 2026-11-02):
 *
 *   "GBU-12 x2 - SCALPEL x6 - 2 RESPAWNS LEFT"
 *
 * CANNOT: "TASKED", "COOLDOWN n S", "REPLACING n S", "UNABLE - NO AIRFRAME".
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: The point, [x, y, z] ATL <ARRAY>
 *
 * Return Value:
 * 0: Can service the point now <BOOL>
 * 1: ETA in seconds, -1 unknown <NUMBER>
 * 2: Why not, "" when it can <STRING>
 * 3: Effect, one line <STRING>
 * 4: Task tokens valid at the point <ARRAY of STRINGs>
 *
 * Example:
 * ["cas:0", [1000, 2000, 0]] call jmfsb_cas_fnc_reach
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_pos", [], [[]]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[false, REACH_ETA_UNKNOWN, "GONE", "", []]};
if (_logic getVariable [QGVAR(gone), false]) exitWith {[false, REACH_ETA_UNKNOWN, WHY_NO_AIRFRAME, "", []]};

private _cls = _logic getVariable [QGVAR(cls), ""];

// THE EFFECT: what it is hung with, and the respawns left.
private _words = (([_cls] call FUNC(stores)) apply {_x select 1}) select [0, REACH_STORES_SHOWN];
private _left = _logic getVariable [QGVAR(respawnsLeft), MODULE_RESPAWNS];
_words pushBack ([format [LEFT_RESPAWNS, _left], LEFT_LAST] select (_left <= 0));
private _effect = _words joinString REACH_SEP;

// BUSY, REARMING OR REPLACING - the one rule the row and the order read.
([_logic] call FUNC(available)) params ["_ok", "_status"];
if (!_ok) exitWith {
    private _why = switch (_status) do {
        case STATUS_COOLDOWN: {format ["COOLDOWN %1 S", ceil ((_logic getVariable [QGVAR(readyAt), 0]) - CBA_missionTime)]};
        case STATUS_REPLACING: {format [WHY_REPLACING, ceil ((_logic getVariable [QGVAR(respawnAt), 0]) - CBA_missionTime)]};
        default {"TASKED"};
    };
    [false, REACH_ETA_UNKNOWN, _why, _effect, []]
};
if (count _pos < 2) exitWith {[false, REACH_ETA_UNKNOWN, "NO TARGET GRID", _effect, []]};

private _speed = ((_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) min getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed")) / KMH_PER_MS;
private _eta = REACH_ETA_UNKNOWN;
if (_speed > 0) then {_eta = (_logic distance2D _pos) / _speed};

[true, _eta, "", _effect, (((SUPPORT_TYPES select 0) select 5) apply {_x select 0})]
