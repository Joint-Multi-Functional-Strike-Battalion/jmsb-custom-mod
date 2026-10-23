#include "script_component.hpp"
/*
 * Author: JMSB
 * The verdict before CONFIRM - the "preview" code of provider "cas" (support
 * core README). Asked on every redraw of the board with exactly the
 * parameters CONFIRM would send, so it reads only what the server published
 * on the module, changes nothing and walks nothing.
 *
 * THE TIME IS THE RUN FUNC(request) WILL FLY: the response delay, then the
 * run-in from where the aircraft appears - the module's spawn distance out,
 * or the INGRESS point when that is further - at the module's speed, capped
 * at what the airframe can do.
 *
 *   strike  "ETA 1 MIN 50 S - 2 AIRFRAMES LEFT"
 *   loiter  "ON STATION IN 1 MIN 50 S - 2 AIRFRAMES LEFT"
 *
 * FALSE ONLY FOR WHAT FUNC(task) WOULD REFUSE: the asset gone, busy, cooling
 * down or out of airframes (FUNC(available)), or no target grid.
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

// The run-in: never shorter than the spawn distance (the floor FUNC(request)
// pushes a close ingress point back to), longer when the INGRESS point is.
private _dist = _logic getVariable [QGVAR(spawnDistance), 4000];
private _ingress = _prm param [8, []];
if !(_ingress isEqualType []) then {_ingress = []};
if (count _ingress >= 2) then {
    _dist = _dist max (_pos distance2D _ingress);
};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _speed = ((_logic getVariable [QGVAR(speed), 400]) min getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed")) / KMH_PER_MS;
private _eta = _logic getVariable [QGVAR(spawnDelay), 30];
if (_speed > 0) then {_eta = _eta + _dist / _speed};

private _line = format [
    ["ETA %1", "ON STATION IN %1"] select (toUpper _task isEqualTo "LOITER"),
    [_eta] call FUNC(fmtEta)
];

// 0 airframes is unlimited, and says nothing.
private _max = _logic getVariable [QGVAR(airframes), 3];
if (_max > 0) then {
    private _left = _max - (_logic getVariable [QGVAR(lost), 0]);
    _line = _line + ([format [" - %1 AIRFRAMES LEFT", _left], " - LAST AIRFRAME"] select (_left isEqualTo 1));
};

[true, _line]
