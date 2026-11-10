#include "script_component.hpp"
/*
 * Author: YonV
 * A loitering drone is on station: the man who called it gets the gunner's
 * seat if he is ISR, everyone else on the side is told (see XEH_postInit,
 * THE HANDOVER).
 *
 * Sent by the server (FUNC(request)) by remoteExec to the module's side and
 * taken only from the server (review S7: it was a global CBA event, so any
 * client could name any drone and himself as the caller and take its seat).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: Who called it <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _caller] remoteExecCall ["jmfsb_cas_fnc_onStation", west]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_caller", objNull, [objNull]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("onStation: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _logic || {isNull _veh}) exitWith {};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];

if (player isNotEqualTo _caller) exitWith {
    ["SUPPORT", format ["%1 on station over %2 - holding", _callsign, mapGridPosition _veh], "normal"] call EFUNC(messaging,notify);
};

// A DRONE IS FLOWN BY A DRONE CONTROLLER. The ISR flag is the mission's own
// - one variable, set on the man whose job this is, and the same one the
// hacking tablet gates on - so a rifleman who calls a loiter gets an
// aircraft holding overhead and his ISR gets the seat.
if !([player] call EFUNC(common,isISR)) exitWith {
    ["SUPPORT", format ["%1 on station - your ISR operator can take the feed from his DRONES board", _callsign], "high"] call EFUNC(messaging,notify);
};

// The link first: without it there is no seat, and the man is told why
// (uavControl says it - not the UAV operator, no DATA link, ...).
if (isNil QEFUNC(devices,uavControl)) exitWith {
    WARNING_1("%1: jmfsb_devices is not loaded - no drone control without a UAV terminal",_callsign);
};
if !(["link", _veh] call EFUNC(devices,uavControl)) exitWith {
    ["SUPPORT", format ["%1 on station - holding; you cannot take it", _callsign], "high"] call EFUNC(messaging,notify);
};

["SUPPORT", format ["%1 on station - you have the gunner", _callsign], "high"] call EFUNC(messaging,notify);

// THE SEAT ONE SECOND LATER, as it always was: the airframe and its crew
// are a moment old, and a seat asked for in the frame they appear in asks
// an AI that is not settled yet.
[{
    params ["_veh", "_callsign"];
    if (!alive _veh) exitWith {};

    private _gunner = gunner _veh;
    if (isNull _gunner) then {_gunner = _veh turretUnit [0]};
    if (isNull _gunner) exitWith {
        WARNING_2("'%1' has no gunner's seat - %2 keeps the link and nothing else",typeOf _veh,_callsign);
    };

    ["take", _veh, _gunner] call EFUNC(devices,uavControl);
}, [_veh, _callsign], SEAT_DELAY] call CBA_fnc_waitAndExecute;
