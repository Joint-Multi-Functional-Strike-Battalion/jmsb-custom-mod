#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the Ambient Kamikaze module and runs the clock. PLACING THE MODULE
 * IS THE ENABLE - no module, no drones.
 *
 * Each run FUNC(kamikazeRun) flies a real aircraft at a building near a
 * player - audible, visible, killable. The module only decides how often
 * and with what airframe.
 *
 * Arguments (module standard):
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

private _markers = ((_logic getVariable ["markers", ""]) splitString " ,")
    select { _x isNotEqualTo "" && {markerShape _x isNotEqualTo ""} };

// THE MODULE'S OWN AREA COUNTS AS ONE OF THEM. Resize it in Eden or Zeus and
// the ambience runs inside that rectangle - see FUNC(areaMarker), which makes
// it into a marker so the gate downstream needs no second way of describing an
// area. Named markers still work and still add to it: the module is the easy
// answer, a marker somebody already drew is the precise one.
private _own = [_logic, "kam"] call FUNC(areaMarker);
if (_own isNotEqualTo "") then { _markers pushBack _own };

// D59: whose drones is never asked - the side is whoever the players are at
// war with, asked of the engine on the first tick. Nothing answering hostile,
// the default east keeps the vanilla OPFOR quadcopter.
//
// ASKED HERE, ANSWERED LATER. A module function runs BETWEEN preInit and
// postInit: EGVAR(common,playerSide) is declared in common's postInit and
// did not exist yet, so this threw "undefined variable" and took the whole
// module down with it. The side is resolved on the first tick instead -
// see the scheduler below.
private _side = east;

// Named classes are honoured as given; an empty field takes the side's
// vanilla quadcopter, chosen on the first run once the side is known.
private _drones = ((_logic getVariable ["droneClasses", ""]) splitString " ,")
    select { _x isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _x)} };

private _intMin = (_logic getVariable ["intervalMin", 420]) max 60;
private _intMax = (_logic getVariable ["intervalMax", 900]) max _intMin;

private _cfg = createHashMapFromArray [
    ["markers", _markers],
    ["drones", _drones],
    ["side", _side],
    ["speed", (_logic getVariable ["diveSpeed", 40]) max 10],
    ["intMin", _intMin],
    ["intMax", _intMax],
    ["bandMin", (_logic getVariable ["bandMin", 150]) max 50],
    ["bandMax", (_logic getVariable ["bandMax", 500]) max 100],
    ["nextAt", CBA_missionTime + _intMin + random (_intMax - _intMin)]
];

INFO_3("ambient kamikaze up for %1: every %2-%3s",_side,_intMin,_intMax);

[{
    params ["_args", "_handle"];
    _args params ["_logic", "_cfg"];

    if (isNull _logic) exitWith { [_handle] call CBA_fnc_removePerFrameHandler };
    if (CBA_missionTime < (_cfg get "nextAt")) exitWith {};
    // THE RETRY, NOT THE INTERVAL, WHEN THERE IS NOTHING TO HIT - see
    // AMB_RETRY. Rolling the next fire time here and then finding no target
    // burnt the whole wait on a tick that did nothing.
    _cfg set ["nextAt", CBA_missionTime + AMB_RETRY];

    // WHOSE DRONES, decided on the first run rather than at module time -
    // common's postInit has not run when a module function does. A side
    // hostile to the players, their vanilla quadcopter if the field named no
    // class of its own, and both settle once.
    //
    // THE FIRST HOSTILE SIDE, ASKED OF THE ENGINE. This used to walk the ALiVE
    // adapter's commanders and take the side of the first one at war with the
    // players. There are no commanders now, and the question was never really
    // about them: it is "who is fighting these players", which getFriend
    // answers directly. The module's own Side field overrides it either way.
    if (!(_cfg getOrDefault ["sideKnown", false])) then {
        _cfg set ["sideKnown", true];

        private _pside = missionNamespace getVariable [QEGVAR(common,playerSide), west];
        {
            if (_x getFriend _pside < 0.6) exitWith { _cfg set ["side", _x] };
        } forEach [east, independent, west];

        if ((_cfg get "drones") isEqualTo []) then {
            _cfg set ["drones", [switch (_cfg get "side") do {
                case west: {"B_UAV_01_F"};
                case independent: {"I_UAV_01_F"};
                default {"O_UAV_01_F"};
            }]];
        };

        INFO_2("ambient kamikaze: %1 flies %2",_cfg get "side",_cfg get "drones");
    };

    private _at = [_cfg get "markers", _cfg get "bandMin", _cfg get "bandMax", "ambient kamikaze"] call FUNC(pickBuilding);
    if (_at isEqualTo []) exitWith {};

    // A target was found, so the real interval starts now.
    _cfg set ["nextAt", CBA_missionTime + (_cfg get "intMin") + random ((_cfg get "intMax") - (_cfg get "intMin"))];

    [_at, selectRandom (_cfg get "drones"), _cfg get "speed", _cfg get "markers"] call FUNC(kamikazeRun);
}, AMB_TICK, [_logic, _cfg]] call CBA_fnc_addPerFrameHandler;
