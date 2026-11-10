#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a terminal has been disabled by hand (FUNC(disableStart)). Its zone
 * comes out of the registry for good - the same end as destroying or hacking
 * it - the terminal is flagged so no menu offers it again, and the player who
 * did it is told.
 *
 * Arguments:
 * 0: The terminal <OBJECT>
 * 1: Who disabled it <OBJECT>
 *
 * Return Value:
 * A zone was ended <BOOL>
 *
 * Example:
 * [_terminal, _player] call jmfsb_jamming_fnc_disableSite
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (!isServer || {isNull _obj}) exitWith {false};
if (isNil QGVAR(jammers)) exitWith {false};
// By remoteExec (review R1: it was a CBA event, so any client could switch off
// any jammer from anywhere). The man is the sender's own, and the client's
// checks run again here: a live jammer he may disable, and he is at it.
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("disableSite: refused - machine %1 named %2",remoteExecutedOwner,_unit);
    false
};
if (!([_obj, _unit] call FUNC(canDisable)) || {_unit distance _obj > DISABLE_RANGE + DISABLE_RANGE_SLACK}) exitWith {
    WARNING_2("disableSite: refused - %1 cannot disable the jammer at %2 from where he is",name _unit,mapGridPosition _obj);
    false
};

private _ended = false;
{
    if ((_x param [ZONE_OBJ, objNull]) isEqualTo _obj) then {
        _ended = [_x param [ZONE_ID, ""]] call FUNC(removeZone) || _ended;
    };
} forEach +GVAR(jammers);

_obj setVariable [QGVAR(disabled), true, true];
_obj setVariable [QGVAR(disabledBy), name _unit, true];
INFO_2("jammer at %1 disabled by %2",mapGridPosition _obj,name _unit);

if (!isNull _unit) then {
    ["JAMMER", "Site disabled - the zone is down.", NOTIFY_OK, _unit] call EFUNC(notify,broadcast);
};

_ended
