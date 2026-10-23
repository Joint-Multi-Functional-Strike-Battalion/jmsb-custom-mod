#include "script_component.hpp"
/*
 * Author: JMSB
 * Every machine: the roster the server published - per player his radio nets
 * (from his RF fill) and his EMCON level - indexed by player UID. The server
 * calls it directly, since a public variable handler does not fire where the
 * variable was set.
 *
 * Arguments:
 * 0: Variable name (unused) <STRING>
 * 1: Roster [[unit, uid, nets, emcon], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jmfsb_voice_roster", _roster] call jmfsb_voice_fnc_receiveRoster
 *
 * Public: No
 */

params ["", ["_roster", [], [[]]]];

GVAR(roster) = _roster;
private _index = createHashMap;
{
    _index set [_x select 1, _x];
} forEach _roster;
GVAR(rosterIndex) = _index;

if (hasInterface && !isNull player) then {
    private _before = GVAR(myNets);
    GVAR(myNets) = [player] call FUNC(nets);
    if (_before isNotEqualTo GVAR(myNets)) then {
        [] call FUNC(checkActive);
        [QGVAR(netsChanged), []] call CBA_fnc_localEvent;
    };
};
