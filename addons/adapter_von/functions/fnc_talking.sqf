#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "talking", client, every frame (and on each pushed key event):
 * which other players are talking, on which net. A speaker who pushed his
 * key-down (fnc_keyed) talks on that net until his key-up, whatever
 * getPlayerChannel says; his entry is dropped when he dies, respawns or
 * leaves. Anyone else is read from getPlayerChannel - the FALLBACK for a
 * speaker whose key event did not arrive. When a speaker's channel changes
 * his volume for this listener is set for it in the same pass
 * (fnc_applyVolume), so his first words come at the mesh volume. The local
 * player is not in it: his own talking is his push-to-talk (fnc_ptt).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, net], ...] talking now, others only <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_talking
 *
 * Public: No
 */

private _out = [];
private _seen = [];
{
    if (_x isEqualTo player || !(_x isKindOf "CAManBase")) then {continue};
    private _uid = getPlayerUID _x;
    _seen pushBack _uid;
    private _ch = getPlayerChannel _x;
    private _net = "";
    private _push = GVAR(keyed) get _uid;
    if (!isNil "_push") then {
        _push params ["_by", "_pushCh", "_pushNet"];
        if (_by isEqualTo _x && alive _x) then {
            _ch = _pushCh;
            _net = _pushNet;
        } else {
            GVAR(keyed) deleteAt _uid;
        };
    };
    if (_ch isNotEqualTo (GVAR(talkCh) getOrDefault [_uid, CH_NONE])) then {
        GVAR(talkCh) set [_uid, _ch];
        [_x, _ch, _net] call FUNC(applyVolume);
    };
    if (_ch > CH_NONE) then {
        if (_net isEqualTo "") then {_net = [_x, _ch] call FUNC(netOf)};
        if (_net isNotEqualTo "") then {_out pushBack [_x, _net]};
    };
} forEach allPlayers;

{
    GVAR(talkCh) deleteAt _x;
    GVAR(keyed) deleteAt _x;
} forEach ((keys GVAR(talkCh)) + (keys GVAR(keyed)) - _seen);

_out
