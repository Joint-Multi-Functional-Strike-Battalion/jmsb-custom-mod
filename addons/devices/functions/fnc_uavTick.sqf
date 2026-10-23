#include "script_component.hpp"
/*
 * Author: JMSB
 * Keeps the drone link and the seat honest (FUNC(uavControl)), every UAV_TICK
 * seconds. Nothing linked and no seat held: nothing to do.
 *
 *   THE LINK drops - and the seat with it - when the player dies, or when
 *   FUNC(uavCan) stops letting him have the drone: it is gone, it changed side
 *   (hacked), he lost the trait, or somebody else holds it.
 *   THE SEAT is given back, the link kept, when the DATA link is lost, the seat
 *   is gone or out of the drone, he is unconscious, or the camera is back on
 *   him without a release (something else switched it) - a controller left in
 *   a seat he cannot see through is a black screen he cannot get out of.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_devices_fnc_uavTick
 *
 * Public: No
 */

private _uav = GVAR(uavLinked);
if (isNull _uav && !GVAR(uavActive)) exitWith {};

private _fnc_say = {
    params ["_text"];
    if (_text isEqualTo "" || {isNil QEFUNC(messaging,notify)}) exitWith {};
    [UAV_NOTIFY_TITLE, _text, "high"] call EFUNC(messaging,notify);
};

if (!alive player) exitWith {["unlink"] call FUNC(uavControl)};

([_uav, player, false] call FUNC(uavCan)) params ["_ok", "_why", "_quality"];
if (!_ok) exitWith {
    [format ["Drone link dropped. %1", _why]] call _fnc_say;
    ["unlink"] call FUNC(uavControl);
};

if (!GVAR(uavActive)) exitWith {};

private _seat = GVAR(uavSeat);
private _release = switch (true) do {
    case (!alive _seat || (vehicle _seat) isNotEqualTo _uav): {"Drone seat lost - control released."};
    case (_quality > UAV_QUALITY_UNKNOWN && _quality < UAV_LINK_LOST): {"No DATA link - control released."};
    case ([player] call EFUNC(common,isUnconscious)): {""};
    case (cameraOn isEqualTo (vehicle player)): {""};
    default {nil};
};
if (isNil "_release") exitWith {};

["release"] call FUNC(uavControl);
[_release] call _fnc_say;
