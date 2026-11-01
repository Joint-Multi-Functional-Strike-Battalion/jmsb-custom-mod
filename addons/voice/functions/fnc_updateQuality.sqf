#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: MESH DRIVES THE VOICE. For every other player and every radio net
 * of the local player's, the link quality from the slice, held at its last
 * good value for the grace time when the route drops, and 0 on a net he has
 * muted; the adapter is told (its "quality" hook) whenever that changes.
 * VON turns it into the speaker's volume for this listener.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_updateQuality
 *
 * Public: No
 */

if (isNull player) exitWith {};

private _now = CBA_missionTime;
private _nets = (GVAR(myNets) select {(_x select 2) in MESH_KINDS}) apply {_x select 0};
private _seen = createHashMap;
private _units = createHashMap;

{
    private _unit = _x;
    if (_unit isEqualTo player || !(_unit isKindOf "CAManBase")) then {continue};
    private _uid = getPlayerUID _unit;
    _units set [_uid, _unit];
    {
        private _net = _x;
        private _key = _uid + "|" + _net;
        private _raw = [_unit, _net] call FUNC(linkQuality);
        private _eff = _raw;
        if (_raw > 0) then {
            GVAR(lastGood) set [_key, [_now, _raw]];
        } else {
            (GVAR(lastGood) getOrDefault [_key, [-GVAR(grace), 0]]) params ["_at", "_last"];
            if ((_now - _at) < GVAR(grace)) then {_eff = _last};
        };
        GVAR(eff) set [_key, _eff];
        _seen set [_key, true];

        private _heard = [_eff, 0] select (GVAR(muted) getOrDefault [_net, false]);
        if ((GVAR(applied) getOrDefault [_key, -1]) isNotEqualTo _heard) then {
            GVAR(applied) set [_key, _heard];
            [_unit, _net, _heard] call HOOK("quality");
        };
    } forEach _nets;
} forEach allPlayers;

// A NET HE LEFT IS HEARD NO MORE: the adapter is told 0 for every speaker it
// last heard on it, so it does not keep the last quality (and give it to the
// next call that takes the same CALL slot). A speaker gone from the game needs
// nothing: there is nobody left to hear.
{
    private _key = _x;
    if ((GVAR(applied) get _key) > 0) then {
        private _at = _key find "|";
        private _unit = _units getOrDefault [_key select [0, _at], objNull];
        if (!isNull _unit) then {[_unit, _key select [_at + 1], 0] call HOOK("quality")};
    };
} forEach ((keys GVAR(applied)) select {!(_x in _seen)});

// forget speakers and nets that are gone
{
    private _map = _x;
    {
        _map deleteAt _x;
    } forEach ((keys _map) select {!(_x in _seen)});
} forEach [GVAR(eff), GVAR(applied), GVAR(lastGood)];
