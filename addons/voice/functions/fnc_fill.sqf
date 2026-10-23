#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the local player's sets as RF nodes (rf_register), with the
 * fill - his TEAM net, his C2-kind net, his A2G-kind net when he is on one
 * (FUNC(a2gNet): pilots by seat, the ground as the plan lists them) and DATA.
 * A node is registered when it appears or its object, profile or fill changes
 * (a respawn, a new group, a seat), and unregistered when the set is gone.
 * Nothing is sent when nothing changed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_fill
 *
 * Public: No
 */

if (isNull player) exitWith {};

private _uid = getPlayerUID player;
private _team = [player] call FUNC(teamNet);
// ...his C2-kind and A2G-kind nets, every RTO net that names his squad or
// him, DATA, and his TEAM net.
private _nets = ([[player] call FUNC(c2Net), [player] call FUNC(a2gNet)] select {_x isNotEqualTo ""}) + ([player] call FUNC(customNets)) + FILL_FIXED;
if (_team isNotEqualTo "") then {_nets pushBack _team};

private _seen = [];
{
    _x params ["_kind", "_object", "_profile"];
    private _id = format [NODE_FORMAT, _uid, _kind];
    _seen pushBack _id;
    private _reg = [_object, _profile, _nets, _id, OWNER_TAG, player];
    if (_reg isNotEqualTo (GVAR(sent) getOrDefault [_id, []])) then {
        _reg call EFUNC(rf,register);
        GVAR(sent) set [_id, _reg];
        // the node is new to RF (or re-made): give it the active net again
        [_id, [["activeNet", [GVAR(activeNetId)] call FUNC(rfNet)]]] call EFUNC(rf,setState);
    };
} forEach ([player] call FUNC(radios));

{
    [_x] call EFUNC(rf,unregister);
    GVAR(sent) deleteAt _x;
} forEach ((keys GVAR(sent)) - _seen);

GVAR(myNodes) = _seen;
