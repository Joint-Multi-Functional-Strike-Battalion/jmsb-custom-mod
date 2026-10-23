#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, every SERVER_TICK_S:
 * - the PAC plan re-read; a TEAM net in RF for every group with a player in
 *   it and no net of the plan;
 * - the roster: per player the radio nets his RF nodes hold (the fill - so
 *   keys and fills are what set it, nobody else) and his highest EMCON
 *   level; published when it changes;
 * - MEMBERSHIP CHANGES ONLY FOR KEYS, FILLS AND CALLS: the adapter's "join" /
 *   "leave" for each net that came or went from a player's fill (a respawned
 *   body is joined afresh). A flickering link never changes membership;
 *   that is volume, on the clients;
 * - the calls and callbacks (fnc_srvCallTick, fnc_srvCallbacks), then the
 *   call table published when it changed.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_voice_fnc_serverTick
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

[] call FUNC(planRefresh);
private _players = allPlayers select {_x isKindOf "CAManBase"};

// a group with no net of the plan gets its own TEAM net (pac makes the plan's)
{
    private _team = [_x] call FUNC(teamNet);
    if (_team isNotEqualTo "" && !(_team in GVAR(teamNets)) && !(_team in GVAR(planKinds))) then {
        GVAR(teamNets) set [_team, true];
        [_team, [["name", [_team] call FUNC(netName)], ["band", NET_BAND_TEAM], ["source", NET_SOURCE]]] call EFUNC(rf,netSet);
    };
} forEach _players;

private _roster = _players apply {
    private _unit = _x;
    private _nets = [];
    private _emcon = 0;
    {
        _x params ["_id", "", "", "_fill"];
        {
            private _net = _x select 0;
            if (([_net] call FUNC(netKind)) in [KIND_TEAM, KIND_C2, KIND_A2G, KIND_CUSTOM]) then {_nets pushBackUnique _net};
        } forEach _fill;
        private _state = ([_id] call EFUNC(rf,nodeInfo)) getOrDefault ["state", createHashMap];
        _emcon = _emcon max (_state getOrDefault ["emcon", 0]);
    } forEach ([_unit, []] call EFUNC(rf,nodesFor));
    _nets sort true;
    [_unit, getPlayerUID _unit, _nets, _emcon]
};

// membership from the fill
private _uids = [];
{
    _x params ["_unit", "_uid", "_nets"];
    _uids pushBack _uid;
    (GVAR(joined) getOrDefault [_uid, [objNull, []]]) params ["_wasUnit", "_wasNets"];
    if (_wasUnit isNotEqualTo _unit) then {
        if (!isNull _wasUnit) then {
            {
                [_wasUnit, _x] call HOOK("leave");
            } forEach _wasNets;
        };
        _wasNets = [];
    };
    // leaves first: two nets can share one voice channel (C2-kind nets)
    {
        [_unit, _x] call HOOK("leave");
    } forEach (_wasNets - _nets);
    {
        [_unit, _x] call HOOK("join");
    } forEach (_nets - _wasNets);
    GVAR(joined) set [_uid, [_unit, _nets]];
} forEach _roster;
// players gone
{
    private _uid = _x;
    (GVAR(joined) get _uid) params ["_unit", "_nets"];
    if (!isNull _unit) then {
        {
            [_unit, _x] call HOOK("leave");
        } forEach _nets;
    };
    GVAR(joined) deleteAt _uid;
} forEach ((keys GVAR(joined)) - _uids);

if (_roster isNotEqualTo GVAR(roster)) then {
    GVAR(roster) = _roster;
    publicVariable QGVAR(roster);
    [QGVAR(roster), _roster] call FUNC(receiveRoster);
};

[] call FUNC(srvCallTick);
[] call FUNC(srvCallbacks);
[] call FUNC(srvPublish);
