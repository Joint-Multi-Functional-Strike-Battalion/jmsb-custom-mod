#include "script_component.hpp"
/*
 * Author: YonV
 * Which mailboxes a player can see. This is the read permission for the whole
 * addon: the index they are sent and the threads they are allowed to open are
 * both worked out from this list, so there is one answer to "can they see it"
 * rather than one per call site.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * Box ids <ARRAY>
 *
 * Example:
 * private _boxes = [_unit] call jmfsb_messaging_fnc_srvBoxesFor
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _out = [
    format ["P:%1", getPlayerUID _unit],
    format ["G:%1", groupId (group _unit)]
];

// HIS ROLE'S OWN LIST, when the mission keeps one - see FUNC(roleNets).
// His personal box and his own squad's net are never gated: a man can
// always read his own mail and his own squad, whatever his role says.
([_unit] call FUNC(roleNets)) params ["_gated", "_allowed"];
private _fnc_mayRead = {
    params ["_name"];
    !_gated || {_name in _allowed}
};

// Shared boxes are readable by everyone. cTab called them file boxes and filed
// them side-wide; a box only one person can read is a personal box with extra
// steps.
{
    // The box id carries its kind as a prefix - the role config names the
    // net, not the id, so the comparison is made on the name.
    if ((_y get "kind") == "named" && {[_x select [2]] call _fnc_mayRead}) then {
        _out pushBackUnique _x;
    };
} forEach GVAR(boxes);

// AND SO IS EVERY DECLARED SQUAD'S NET - the user's rule, asked three times:
// squad traffic is the platoon's to read, not private mail. DELIVERY is still
// to the squad's own members; reading a net is not membership of it.
{
    if ([_x] call _fnc_mayRead) then {
        _out pushBackUnique format ["G:%1", _x];
    };
} forEach ([] call FUNC(squadNets));

_out
