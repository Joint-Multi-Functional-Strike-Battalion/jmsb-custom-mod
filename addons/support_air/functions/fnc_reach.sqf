#include "script_component.hpp"
/*
 * Author: YonV
 * The "reach" code of provider "air" (support core README, 2026-11-01):
 * whether this asset can fly to one map point, how soon and with what - its
 * row of the board's reach card. Asked once per target click on the viewer's
 * machine, so it reads only what the server published on the module, the way
 * the verdict before CONFIRM (FUNC(preview)) does.
 *
 * THE ETA IS THE PREVIEW'S, FOR THE PLAINEST ORDER: no delay (user,
 * 2026-11-02: virtual until tasked - a class airframe is made over the module
 * when it is tasked), the straight route at NORMAL speed (FUNC(flightTime)) -
 * from where it is when it is out, from the module (or a synced aircraft's
 * stand) otherwise. No VIA, INGRESS, APPROACH or SPEED: those are the
 * player's to add on the screen. Unknown (-1) when the class has no top speed
 * to fly it by.
 *
 *   CAS        "GBU-12 x2 - SCALPEL x4 - 2 SPARE AIRFRAMES"
 *   TRANSPORT  "16 SEATS - LAST AIRFRAME"
 *   QRF        "1 SPARE AIRFRAME"
 *
 * TASKS are the ones this airframe flies (FUNC(tasks)), less the ones the
 * point rules out the way FUNC(preview) does: a HELOCAST over land, an ATTACK
 * RUN for an aircraft out on a task and not on station. PICKUP > LZ and SLINGLOAD stay:
 * their second point is picked on the type screen.
 *
 * CANNOT: "TASKED", "COOLDOWN n S", "REPLACING", "EXPENDED", "HELOCAST NEEDS
 * WATER", "NO TASK FITS".
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
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
 * ["air:0", [1000, 2000, 0]] call jmfsb_support_air_fnc_reach
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_pos", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, REACH_ETA_UNKNOWN, "GONE", "", []]};

private _kind = _logic getVariable [QGVAR(kind), ""];
private _cls = _logic getVariable [QGVAR(cls), ""];
private _synced = _logic getVariable [QGVAR(synced), objNull];

// THE EFFECT: what it brings, and how many more airframes it has (user,
// 2026-11-02: "make sure there is a respawn count for each support, default
// no respawns").
private _left = _logic getVariable [QGVAR(respawnsLeft), 0];
private _spares = [format ["%1 SPARE AIRFRAMES", _left], "1 SPARE AIRFRAME", "LAST AIRFRAME"] select (2 - (_left min 2));
private _words = switch (_kind) do {
    case KIND_CAS: {
        private _src = [_cls, _synced] select (alive _synced);
        ((([_src] call EFUNC(cas,stores)) apply {_x select 1}) select [0, REACH_STORES_SHOWN]) + [_spares]
    };
    case KIND_TRANSPORT: {[format ["%1 SEATS", getNumber (configFile >> "CfgVehicles" >> _cls >> "transportSoldier")], _spares]};
    case KIND_QRF: {[_spares]};
    default {[]};
};
private _effect = (_words select {_x isNotEqualTo ""}) joinString REACH_SEP;

// BUSY, TURNING ROUND OR SPENT - the one rule the row and the order read. A
// transport out on a sortie, and a CAS aircraft on station, are re-taskable.
([_logic] call FUNC(available)) params ["_ok", "_status"];
if (!_ok) exitWith {
    private _why = switch (_status) do {
        case STATUS_EXPENDED: {"EXPENDED"};
        case STATUS_REPLACING: {"REPLACING"};
        case STATUS_COOLDOWN: {format ["COOLDOWN %1 S", ceil ((_logic getVariable [QGVAR(readyAt), 0]) - CBA_missionTime)]};
        default {"TASKED"};
    };
    [false, REACH_ETA_UNKNOWN, _why, _effect, []]
};
if (count _pos < 2) exitWith {[false, REACH_ETA_UNKNOWN, "NO TARGET POINT", _effect, []]};
_pos = [_pos select 0, _pos select 1, 0];

private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _out = _status isNotEqualTo STATUS_IDLE && alive _veh;

// THE TASKS this airframe flies, less what the point rules out.
private _tasks = ([_assetId, []] call FUNC(tasks)) apply {_x select 0};
private _castOnLand = TASK_HELOCAST in _tasks && !surfaceIsWater _pos;
// An aircraft on station flies a run from there (FUNC(casOrder)).
if (_out && _status isNotEqualTo STATUS_ON_STATION) then {_tasks = _tasks - [TASK_RUN]};
if (_castOnLand) then {_tasks = _tasks - [TASK_HELOCAST]};
if (_tasks isEqualTo []) exitWith {
    [false, REACH_ETA_UNKNOWN, ["NO TASK FITS", "HELOCAST NEEDS WATER"] select _castOnLand, _effect, []]
};

// THE ETA, from where it flies from - out, where it is; otherwise its base,
// at once: a class airframe is made over the module when it is tasked (user,
// 2026-11-02: virtual until tasked), a synced one takes off from its stand.
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _from = [_home, getPosATL _veh] select _out;
private _eta = REACH_ETA_UNKNOWN;
if (getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") > 0) then {
    _eta = [_cls, [_from, _pos], SPEED_NORMAL] call FUNC(flightTime);
};

[true, _eta, "", _effect, _tasks]
