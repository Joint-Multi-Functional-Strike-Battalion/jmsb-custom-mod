#include "script_component.hpp"
/*
 * Author: JMSB
 * The players on a voice net, by the voice layer (each one's nets: his fill
 * from the server's roster, his calls, his crew seat). VEH is per vehicle,
 * so for VEH only the crew of the given unit's vehicle count.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Unit whose vehicle VEH means <OBJECT> (default: objNull)
 *
 * Return Value:
 * Players <ARRAY>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_members
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_unit", objNull, [objNull]]];

if (!GVAR(active)) exitWith {[]};
if (_net isEqualTo "") exitWith {[]};
if (_net isEqualTo NET_VEH) exitWith {
    private _vehicle = [_unit] call FUNC(crewOf);
    [(crew _vehicle) select {isPlayer _x && {([_x] call FUNC(crewOf)) isEqualTo _vehicle}}, []] select (isNull _vehicle)
};

allPlayers select {
    private _player = _x;
    _player isKindOf "CAManBase" && {(([_player] call FUNC(nets)) findIf {(_x select 0) isEqualTo _net}) >= 0}
}
