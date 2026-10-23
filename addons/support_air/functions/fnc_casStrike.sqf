#include "script_component.hpp"
/*
 * Author: JMSB
 * One release from a CAS aircraft: find what to hit, put the ordnance on it.
 *
 * WHAT TO HIT is the CAS drones' answer first (EFUNC(cas,acquire)): a laser
 * spot or smoke inside the search radius, then the grid. An ATTACK RUN takes
 * that answer as it stands - a map-grid strike is what was ordered. A SAD
 * that finds nothing painted looks at what the crew KNOWS is there, inside
 * the orbit, and takes the nearest to the grid; nothing known is no release.
 *
 * THE RELEASE IS THE CAS DRONES' TOO (EFUNC(cas,fireAt)): the heaviest
 * air-to-ground store aboard unless the requester picked one, steered onto a
 * dummy laser target. Its once-per-airframe latch is reset first, because a
 * crewed aircraft makes more than one pass.
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
 *
 * Return Value:
 * "fired", "none" (nothing to hit), "unsafe" (friendlies inside the module's
 * Friendly Range of it) or "dry" (nothing left to hit it with) <STRING>
 *
 * Example:
 * [_logic, _veh, _pos, 300, "run", player, false] call jmfsb_support_air_fnc_casStrike
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
    ["_danger", false, [false]]
];

if (!alive _veh || {_pos isEqualTo []}) exitWith {"none"};

private _side = _logic getVariable [QGVAR(side), west];
([_pos, _radius, _side] call EFUNC(cas,acquire)) params ["_aim", "_by", "_track"];

if (_mode isEqualTo "sad" && _by isEqualTo "grid") then {
    private _eyes = effectiveCommander _veh;
    private _known = (_eyes targets [true, _radius, [], 0, _pos]) select {alive _x};
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
if (_aim isEqualTo []) exitWith {"unsafe"};

_veh setVariable [QEGVAR(cas,fired), false];
if !([_veh, _aim, _track] call EFUNC(cas,fireAt)) exitWith {"dry"};

private _word = switch (_by) do {
    case "laser": {"on your spot"};
    case "smoke": {"on your smoke"};
    case "known": {"on a target"};
    default {"on the grid"};
};
[_logic, format ["in hot %1 - %2", _word, mapGridPosition _aim], "high", _requester] call FUNC(say);

"fired"
