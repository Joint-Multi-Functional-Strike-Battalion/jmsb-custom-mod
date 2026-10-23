#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: brings the talking list up to date - every frame (fnc_frame) and
 * at once on a pushed key event (fnc_keyed). Others come from the adapter's
 * "talking" hook (VON: speakers who pushed their key, plus getPlayerChannel
 * as the fallback), the local player from his own key (fnc_transmit); only
 * his nets count. A change of another speaker raises jmfsb_voice_talk [unit,
 * net, on] and, on a radio net he can hear (mesh volume above 0), the
 * squelch open / tail; his static is stopped when he stops.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_talkSync
 *
 * Public: No
 */

if (isNull player) exitWith {};

private _mine = GVAR(myNets) apply {_x select 0};
private _now = ([] call HOOK("talking")) select {(_x select 1) in _mine && (_x select 0) isNotEqualTo player};
if (GVAR(keyLive) && GVAR(keyNet) in _mine) then {_now pushBack [player, GVAR(keyNet)]};

// starts
{
    _x params ["_unit", "_net"];
    if (_x in GVAR(talkers) || _unit isEqualTo player) then {continue};
    [QGVAR(talk), [_unit, _net, true]] call CBA_fnc_localEvent;
    if !(([_net] call FUNC(netKind)) in MESH_KINDS) then {continue};
    private _q = [_unit, _net] call FUNC(heard);
    GVAR(staticNext) set [(getPlayerUID _unit) + "|" + _net, [0, _q, NO_SOUND]];
    if (_q > 0) then {["squelchOpen", _net] call FUNC(playCue)};
} forEach _now;

// stops
{
    _x params ["_unit", "_net"];
    if (_x in _now || _unit isEqualTo player) then {continue};
    [QGVAR(talk), [_unit, _net, false]] call CBA_fnc_localEvent;
    if !(([_net] call FUNC(netKind)) in MESH_KINDS) then {continue};
    private _key = (getPlayerUID _unit) + "|" + _net;
    (GVAR(staticNext) getOrDefault [_key, [0, 0, NO_SOUND]]) params ["", "_was", "_id"];
    if (_id > NO_SOUND) then {stopSound _id};
    if (_was > 0) then {["squelchTail", _net] call FUNC(playCue)};
    GVAR(staticNext) deleteAt _key;
} forEach GVAR(talkers);

GVAR(talkers) = _now;
