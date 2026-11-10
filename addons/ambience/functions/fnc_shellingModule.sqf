#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the Ambient Shelling module and runs the clock. PLACING THE MODULE
 * IS THE ENABLE - no module, no ambience.
 *
 * Every stonk: one building near one player inside the markers, announced
 * on the alert bus, then EFUNC(common,fireBarrage) - the same virtual guns
 * the reaction fallback and the QRF mortars fire, nothing new conjured.
 * A tick that finds nobody in the markers just waits; the war resumes when
 * somebody walks back in.
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
private _own = [_logic, "shell"] call FUNC(areaMarker);
if (_own isNotEqualTo "") then { _markers pushBack _own };

private _shells = ((_logic getVariable ["shellClasses", ""]) splitString " ,")
    select { _x isNotEqualTo "" && {isClass (configFile >> "CfgAmmo" >> _x)} };
if (_shells isEqualTo []) then { _shells = ["Sh_155mm_AMOS", "Sh_82mm_AMOS"] };

private _intMin = (_logic getVariable ["intervalMin", 240]) max 30;
private _intMax = (_logic getVariable ["intervalMax", 600]) max _intMin;

private _cfg = createHashMapFromArray [
    ["markers", _markers],
    ["shells", _shells],
    ["intMin", _intMin],
    ["intMax", _intMax],
    ["roundsMin", (_logic getVariable ["roundsMin", 2]) max 1],
    ["roundsMax", (_logic getVariable ["roundsMax", 5]) max 1],
    ["bandMin", (_logic getVariable ["bandMin", 150]) max 50],
    ["bandMax", (_logic getVariable ["bandMax", 450]) max 100],
    ["nextAt", CBA_missionTime + _intMin + random (_intMax - _intMin)]
];

INFO_2("ambient shelling up: every %1-%2s",_intMin,_intMax);

[{
    params ["_args", "_handle"];
    _args params ["_logic", "_cfg"];

    if (isNull _logic) exitWith { [_handle] call CBA_fnc_removePerFrameHandler };
    if (CBA_missionTime < (_cfg get "nextAt")) exitWith {};
    // THE RETRY, NOT THE INTERVAL, WHEN THERE IS NOTHING TO HIT - see
    // AMB_RETRY. Rolling the next fire time here and then finding no target
    // burnt the whole wait on a tick that did nothing.
    _cfg set ["nextAt", CBA_missionTime + AMB_RETRY];

    private _at = [_cfg get "markers", _cfg get "bandMin", _cfg get "bandMax", "ambient shelling"] call FUNC(pickBuilding);
    if (_at isEqualTo []) exitWith {};

    // A target was found, so the real interval starts now.
    _cfg set ["nextAt", CBA_missionTime + (_cfg get "intMin") + random ((_cfg get "intMax") - (_cfg get "intMin"))];

    private _rounds = round ((_cfg get "roundsMin") + random ((_cfg get "roundsMax") - (_cfg get "roundsMin")));
    private _shell = selectRandom (_cfg get "shells");

    // Perceivable before it is lethal - the bus tells everyone close enough
    // to care, and the first shell is seconds behind the warning.
    ["ARTY", "Incoming artillery fire", _at, 500, 2] call EFUNC(common,alert);
    [_at, _rounds, 60, _shell, _rounds * 4] call EFUNC(common,fireBarrage);

    INFO_2("ambient stonk: %1 rounds on grid %2",_rounds,mapGridPosition _at);
}, AMB_TICK, [_logic, _cfg]] call CBA_fnc_addPerFrameHandler;
