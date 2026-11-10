#include "script_component.hpp"
/*
 * Author: YonV
 * What one jump aircraft is and flies, by its asset id (user, 2026-11-02:
 * "Jump aircraft module"). One place for the row (FUNC(assets)), reach
 * (FUNC(reach)) and the card (FUNC(srvThread)), on the client and the server
 * alike - it reads only what is published.
 *
 *   "jump:<n>"     the JMSB - Jump Aircraft module n (FUNC(moduleJump)): its
 *                  class, call sign, altitudes, defaults, its aircraft while
 *                  one is made (virtual until tasked, 2026-11-02); and
 *                  whether it can take a run - no airframe left (UNABLE - NO
 *                  AIRFRAME, the respawn count), a loss's Respawn Delay
 *                  running (REPLACING IN n S), tasked (TASKED), flying home
 *                  to be removed (RTB), its cooldown running; else IDLE -
 *                  ready, virtual
 *   "jump:<side>"  the side's own jump aircraft, there only while no module
 *                  of that side is: the side's cargo aircraft
 *                  (FUNC(aircraftClass)), SKYTRAIN, the settings' altitudes,
 *                  passes, exit and bay, no airframe up, no cooldown - made
 *                  at the run-in, one run per squad at a time, as before the
 *                  module
 *
 * Arguments:
 * 0: Asset id <STRING>
 *
 * Return Value:
 * The asset, an empty HASHMAP when there is none <HASHMAP>
 *   "logic"     the module, objNull for a side's own aircraft <OBJECT>
 *   "side", "cls", "callsign"
 *   "alts"      [HALO, HAHO, STATIC] m, the order of TYPES <ARRAY>
 *   "passes", "exit", "bay"   the card's defaults and the bay
 *   "veh"       its aircraft while one is made, objNull for a side's own <OBJECT>
 *   "status"    the row's status, STATUS_IDLE when it can take a run <STRING>
 *   "why"       why it cannot, "" when it can <STRING>
 *
 * Example:
 * ["jump:0"] call jmfsb_jumpmaster_fnc_asset
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _parts = _assetId splitString ID_SEP;
if ((_parts param [0, ""]) isNotEqualTo JUMP_KIND) exitWith {createHashMap};
private _word = _parts param [1, ""];

// THE SIDE'S OWN, from the settings - none while a module of the side is placed.
private _sideAt = JUMP_SIDES findIf {(toLower str _x) isEqualTo _word};
if (_sideAt >= 0) exitWith {
    private _side = JUMP_SIDES select _sideAt;
    private _asset = createHashMap;
    if (([_side] call FUNC(modules)) isEqualTo []) then {
        _asset = createHashMapFromArray [
            ["logic", objNull],
            ["side", _side],
            ["cls", [_side] call FUNC(aircraftClass)],
            ["callsign", JUMP_CALLSIGN],
            ["alts", [GVAR(haloAltitude), GVAR(haloAltitude), GVAR(staticAltitude)] apply {round _x}],
            ["passes", GVAR(passesDefault)],
            ["exit", GVAR(exitDefault)],
            ["bay", GVAR(bay)],
            ["veh", objNull],
            ["status", STATUS_IDLE],
            ["why", ""]
        ];
    };
    _asset
};

// A MODULE'S.
private _n = parseNumber _word;
if (_n < 0 || (str _n) isNotEqualTo _word) exitWith {createHashMap};
private _logic = (missionNamespace getVariable [QGVAR(entities), []]) param [_n, objNull];
if (isNull _logic) exitWith {createHashMap};

// ITS AIRCRAFT (user, 2026-11-02: virtual until tasked; the respawn count):
// gone for good, a loss's Respawn Delay running, tasked, flying home to be
// removed, turning round - or virtual and ready, its respawns left.
private _phase = _logic getVariable [QGVAR(airPhase), AIR_VIRTUAL];
private _wait = ceil ((_logic getVariable [QGVAR(readyAt), 0]) - CBA_missionTime);
private _replace = ceil ((_logic getVariable [QGVAR(replaceAt), 0]) - CBA_missionTime) max 0;
private _state = switch (true) do {
    case (_phase isEqualTo AIR_GONE): {[STATUS_EXPENDED, WHY_NO_AIRFRAME]};
    case (_logic getVariable [QGVAR(busy), false]): {[STATUS_TASKED, WHY_TASKED]};
    case (_phase isEqualTo AIR_REPLACING): {[STATUS_REPLACING, format [WHY_REPLACING, _replace]]};
    case (_phase isEqualTo AIR_HOME): {[STATUS_RTB, WHY_RTB]};
    case (_wait > 0): {[STATUS_COOLDOWN, format [WHY_COOLDOWN, _wait]]};
    default {[STATUS_IDLE, ""]};
};

createHashMapFromArray [
    ["logic", _logic],
    ["side", _logic getVariable [QGVAR(side), sideUnknown]],
    ["cls", _logic getVariable [QGVAR(cls), ""]],
    ["callsign", _logic getVariable [QGVAR(callsign), JUMP_CALLSIGN]],
    ["alts", _logic getVariable [QGVAR(alts), [ALT_FREEFALL_DEFAULT, ALT_FREEFALL_DEFAULT, ALT_STATIC_DEFAULT]]],
    ["passes", _logic getVariable [QGVAR(passes), MODULE_PASSES]],
    ["exit", _logic getVariable [QGVAR(exit), EXIT_AUTO]],
    ["bay", _logic getVariable [QGVAR(bay), BAY_SEATS]],
    ["veh", _logic getVariable [QGVAR(veh), objNull]],
    ["status", _state select 0],
    ["why", _state select 1]
]
