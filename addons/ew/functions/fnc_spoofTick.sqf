#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, each DF tick: moves the GPS of the AI men the spoof engine has to
 * keep (players are FUNC(publish)'s, every tick):
 *
 *   - every man of a net spoofed by a hack (FUNC(spoofNode)), while it lasts
 *     and until each has walked back to true
 *   - the enemy's DF sensors (FUNC(aiSensors)) while any spoofer is on air,
 *     so a player's spoofer walks an AI set off as it walks a player's
 *   - any AI man still off true, so he walks back
 *
 * A hacked net is forgotten once its time is up and all its men are on true.
 *
 * Arguments:
 * 0: Seconds since the last call <NUMBER>
 * 1: The AI sensors' men this tick <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [GVAR(dfTick), _aiMen] call jmfsb_ew_fnc_spoofTick
 *
 * Public: No
 */

params [["_dt", 0, [0]], ["_aiMen", [], [[]]]];

private _now = CBA_missionTime;
private _men = [];

if ((values GVAR(jammers)) findIf {(_x get "tx") && (_x get "mode") isEqualTo MODE_SPOOF} >= 0) then {
    _men append _aiMen;
};

private _gone = [];
{
    _y params ["_group", "_until"];
    if (isNull _group) then {
        _gone pushBack _x;
        continue;
    };
    private _crew = (units _group) select {alive _x && !isPlayer _x};
    _men append _crew;
    if (_now >= _until && {_crew findIf {(hashValue _x) in GVAR(spoof)} < 0}) then {_gone pushBack _x};
} forEach GVAR(spoofNodes);
{
    GVAR(spoofNodes) deleteAt _x;
} forEach _gone;

_gone = [];
{
    // A player's entry is his UID's, moved by FUNC(publish), and outlives
    // his body.
    _y params ["", "", "", ["_unit", objNull], ["_isPlayer", true]];
    if (_isPlayer) then {continue};
    if (isNull _unit || !alive _unit) then {
        _gone pushBack _x;
        continue;
    };
    _men pushBack _unit;
} forEach GVAR(spoof);
{
    GVAR(spoof) deleteAt _x;
} forEach _gone;

{
    [_x, _dt] call FUNC(spoof);
} forEach (_men arrayIntersect _men);
