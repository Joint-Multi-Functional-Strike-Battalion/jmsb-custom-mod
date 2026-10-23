#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: SPOT JAM on a net (DESIGN_EW "Threat warning") - every player in
 * reach of an enemy spot jammer who holds the net it is aimed at is told
 * which net, once per THREAT_SHOW_S. What he hears is the noise on that one
 * net rising while his others stay clean, which is how a spot jammer gives
 * itself away.
 *
 * Arguments:
 * 0: Players <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [allPlayers] call jmfsb_ew_fnc_spotWarn
 *
 * Public: No
 */

params [["_players", [], [[]]]];

private _now = CBA_missionTime;
{
    private _j = _y;
    private _jamId = _x;
    if (!(_j get "tx") || {(_j get "mode") isNotEqualTo MODE_SPOT}) then {continue};
    private _host = _j get "host";
    if (isNull _host || {!alive _host}) then {continue};
    private _net = _j get "net";
    {
        private _p = _x;
        if ((str side group _p) isEqualTo (_j get "side")) then {continue};
        if ((_p distance _host) > GVAR(jamRange)) then {continue};
        private _key = getPlayerUID _p + "|" + _jamId;
        if (_now - (GVAR(spotTold) getOrDefault [_key, -1e9]) < THREAT_SHOW_S) then {continue};
        private _holds = ([_p, []] call EFUNC(rf,nodesFor)) findIf {
            ((_x select 3) findIf {(_x select 0) isEqualTo _net}) >= 0
        };
        if (_holds < 0) then {continue};
        GVAR(spotTold) set [_key, _now];
        [_p, THREAT_SPOT, format ["%1 IS BEING SPOT-JAMMED", _net], "GO TO THE PACE ALTERNATE OR CHANGE BAND, DF THE JAMMER"] call FUNC(warn);
    } forEach _players;
} forEach GVAR(jammers);
