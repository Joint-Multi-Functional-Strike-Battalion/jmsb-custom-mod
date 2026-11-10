#include "script_component.hpp"
/*
 * Author: YonV
 * Begins one attack pass of a CAS aircraft: finds what to hit, and hands the
 * run to the CAS drones' pass (EFUNC(cas,passBegin) - 2026-11-05, modelled
 * on how Simplex Support Services flies a strafe; no code of it used). The
 * caller's watch ticks the pass (EFUNC(cas,passTick)) until it is over. Was
 * one trigger pull inside a 700 m ring from wherever the AI had the aircraft.
 *
 * WHAT TO HIT is the CAS drones' answer first (EFUNC(cas,acquire)): a laser
 * spot or smoke inside the search radius, then the grid. An ATTACK RUN takes
 * that answer as it stands - a map-grid strike is what was ordered - and the
 * pass keeps looking for a spot or smoke on the way in. A SAD that finds
 * nothing painted looks at what the crew KNOWS is there, inside the orbit,
 * and takes the nearest to the grid; nothing known is no release. What the
 * requester knows there counts too (2026-11-01): a fixed-wing comes in from
 * its off-map hold for it, and its crew has not seen the grid yet.
 *
 * THE PASS lines the aircraft up on the ingress bearing - the caller's, or
 * from where it is - dives it on the aim, releases the salvo of the store
 * asked for (QEGVAR(cas,ordnance), else the heaviest aboard) on a solution,
 * and hands it back; the aircraft is ordered through FUNC(moveTo) while it
 * lines up, and a helicopter's own order (FUNC(heliOrder)) is dropped when
 * the dive takes the airframe.
 *
 * FRIENDLIES FIRST, the way Simplex checks its friendly range: a release
 * whose aim point has the players' own side inside the module's Friendly
 * Range is held - unless the requester asked for DANGER CLOSE.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The grid, ATL <ARRAY>
 * 3: Search radius, m <NUMBER>
 * 4: "run" or "sad" <STRING>
 * 5: Who asked <OBJECT>
 * 6: Danger close - release with friendlies near the aim point <BOOL> (optional, default false)
 * 7: Ingress bearing, from the aim towards where it comes in from; -1 for from where it is <NUMBER> (optional, default -1)
 *
 * Return Value:
 * "begun", "none" (nothing to hit), "unsafe" (friendlies inside the module's
 * Friendly Range of it) or "dry" (nothing left to hit it with) <STRING>
 *
 * Example:
 * [_logic, _veh, _pos, 300, "run", player, false, 270] call jmfsb_support_air_fnc_casStrike
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_veh", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_radius", 0, [0]],
    ["_mode", "run", [""]],
    ["_requester", objNull, [objNull]],
    ["_danger", false, [false]],
    ["_inDir", -1, [0]]
];

if (!alive _veh || {_pos isEqualTo []}) exitWith {"none"};

private _side = _logic getVariable [QGVAR(side), west];
([_pos, _radius, _side] call EFUNC(cas,acquire)) params ["_aim", "_by", "_track"];

if (_mode isEqualTo "sad" && _by isEqualTo "grid") then {
    private _eyes = effectiveCommander _veh;
    private _known = (_eyes targets [true, _radius, [], 0, _pos]) select {alive _x};
    if (!isNull _requester) then {
        _known append ((_requester targets [true, _radius, [], 0, _pos]) select {alive _x});
    };
    _track = [_known, _pos] call EFUNC(cas,nearestTo);
    _aim = if (isNull _track) then {[]} else {getPosATL _track};
    _by = "known";
};
if (_aim isEqualTo []) exitWith {"none"};

private _range = _logic getVariable [QGVAR(friendlyRange), 0];
if (!_danger && _range > 0) then {
    private _near = (_aim nearEntities [["CAManBase", "LandVehicle", "Ship", "StaticWeapon"], _range]) select {
        alive _x && {(side group _x) isEqualTo _side}
    };
    if (_near isNotEqualTo []) then {_aim = []};
};
// A release held for friendlies is said once a sortie (the flag is reset
// with the sortie, FUNC(casLaunch), and when it is moved on station).
if (_aim isEqualTo []) exitWith {
    if !(_logic getVariable [QGVAR(heldSaid), false]) then {
        _logic setVariable [QGVAR(heldSaid), true];
        [_logic, format ["holding - friendlies within %1 m of the target, call DANGER CLOSE to clear it", _range], "high", _requester, false] call FUNC(say);
    };
    "unsafe"
};

if (_inDir < 0) then {_inDir = _aim getDir _veh};
private _opts = createHashMapFromArray [
    // The line-up is flown by this addon's orders; the dive drops a
    // helicopter's own order (FUNC(heliOrderTick) would give it again).
    ["order", {
        params ["_veh", "_point"];
        if (_point isEqualTo []) exitWith {_veh setVariable [QGVAR(order), nil]};
        [_veh, _point, "FULL"] call FUNC(moveTo);
    }],
    ["search", [_pos, _radius, _side, _range, _danger]],
    ["by", _by]
];
if !([_veh, _aim, _track, _inDir, _opts] call EFUNC(cas,passBegin)) exitWith {"dry"};

private _word = switch (_by) do {
    case "laser": {"on your spot"};
    case "smoke": {"on your smoke"};
    case "known": {"on a target"};
    default {"on the grid"};
};
[_logic, format ["in hot %1 - %2", _word, mapGridPosition _aim], "high", _requester] call FUNC(say);
INFO_4("%1 pass begun %2 at %3 from %4 deg",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_word,mapGridPosition _aim,round _inDir);

"begun"
