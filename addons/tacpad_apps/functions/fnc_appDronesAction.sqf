#include "script_component.hpp"
/*
 * Author: JMSB
 * The DRONES board's buttons, on the picked drone. There is no vanilla UAV
 * terminal any more (user, 2026-10-20: out of the arsenal), so the link and
 * the seat are the devices' own (EFUNC(devices,uavControl)), with their gate
 * (EFUNC(devices,uavCan): the UAV operator, the players' side, nobody else
 * holding it, the DATA link):
 *
 *   "connect"     links the drone - the board's "selected drone"; one at a time
 *   "disconnect"  gives the seat back and drops the link
 *   "control"     the gunner's seat (the driver's when there is none) by
 *                 remoteControl; closes the map or the tablet first so the
 *                 player is looking through it. Out again by the drone's action
 *                 menu or the tablet key.
 *   "mark"        a local marker where the optic is looking (FUNC(appDronesCamera)),
 *                 or under the drone when the optic sees no ground
 *
 * ORDERS, on a drone linked to the player and through the gate again at the
 * press. They go to the drone's AI wherever its crew is local
 * (EFUNC(devices,uavOrder)):
 *
 *   "orbit"       a LOITER circle where the drone is, DRONES_ORBIT_RADIUS
 *   "goto"        arms a map pick (FUNC(appDronesPick)); the click sends the
 *                 drone there at its height, to loiter
 *   "lase"        on: the designator onto the gunner's assigned target, else
 *                 the point under the optic, else under the drone; off when it
 *                 is lasing. Refused, with the reason, on an airframe with no
 *                 laser.
 *   "rtb"         home (EFUNC(devices,uavHome): its launch point, the nearest
 *                 staging zone or patrol base, else the operator); lands there
 *                 when it can, else loiters
 *
 * "mode" switches a Drone40 variant (relay / decoy / jammer / off,
 * jmfsb_drone40_fnc_setMode, server-side) - gated like CONNECT: on a drone the
 * player holds or may link.
 *
 * Control needs the DATA link (DESIGN_TABLET_APPS.md, DRONES); an unknown link
 * (no RF) does not block, a lost one does.
 *
 * Arguments:
 * 0: Action <STRING>
 * 1: Drone <OBJECT>
 * 2: Argument - the mode for "mode" <ANY> (optional, default "")
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["connect", _uav] call jmfsb_tacpad_apps_fnc_appDronesAction
 * ["mode", _uav, "jammer"] call jmfsb_tacpad_apps_fnc_appDronesAction
 *
 * Public: No
 */

params [["_action", "", [""]], ["_uav", objNull, [objNull]], ["_arg", ""]];

if (!alive _uav) exitWith {
    ["DRONES", "That drone is gone.", "high"] call EFUNC(messaging,notify);
    false
};

private _devices = !isNil QEFUNC(devices,uavControl);
private _mine = _devices && {(["linked"] call EFUNC(devices,uavControl)) isEqualTo _uav};

private _fnc_say = {
    params ["_text", ["_level", "high"]];
    ["DRONES", _text, _level] call EFUNC(messaging,notify);
};

// The orders' gate: his link, and the gate the link was given by - asked
// again, so a lost DATA link or a lost trait refuses at the press.
private _fnc_may = {
    if (!_mine) exitWith {
        ["Connect to the drone first."] call _fnc_say;
        false
    };
    ([_uav] call EFUNC(devices,uavCan)) params ["_ok", "_why"];
    if (!_ok) then {[_why] call _fnc_say};
    _ok
};

// An order to the drone's AI, said back either way.
private _fnc_order = {
    params ["_order", "_args", "_said"];
    ([_order, _uav, _args] call EFUNC(devices,uavOrder)) params ["_ok", "_why"];
    if (_ok) then {[_said, "normal"] call _fnc_say} else {[_why] call _fnc_say};
    _ok
};

switch (_action) do {
    case "connect": {
        if (!_devices) exitWith {
            ["Drone control needs the JMSB devices addon."] call _fnc_say;
            false
        };
        ["link", _uav] call EFUNC(devices,uavControl)
    };
    case "disconnect": {
        if (!_mine) exitWith {false};
        ["unlink"] call EFUNC(devices,uavControl)
    };
    case "control": {
        if (!_mine) exitWith {
            ["Connect to the drone first."] call _fnc_say;
            false
        };
        ["take", _uav] call EFUNC(devices,uavControl)
    };
    case "orbit": {
        if !(call _fnc_may) exitWith {false};
        ["orbit", [DRONES_ORBIT_RADIUS], format ["Orbiting %1.", mapGridPosition _uav]] call _fnc_order
    };
    case "goto": {
        if !(call _fnc_may) exitWith {false};
        ["arm", _uav] call FUNC(appDronesPick)
    };
    case "lase": {
        if !(call _fnc_may) exitWith {false};
        if ((_uav getVariable [QEGVAR(devices,uavLase), []]) isNotEqualTo []) exitWith {
            ["lase", [false], "Laser off."] call _fnc_order
        };

        // What to lase: the gunner's own target, else where the optic looks
        // (the feed's ground point, while the feed shows this drone), else
        // the ground under the drone.
        private _gunner = gunner _uav;
        private _target = if (isNull _gunner) then {objNull} else {assignedTarget _gunner};
        if (!alive _target) then {
            _target = if ((uiNamespace getVariable [QGVAR(feedUav), objNull]) isEqualTo _uav) then {
                uiNamespace getVariable [QGVAR(feedTarget), []]
            } else {[]};
            if (_target isEqualTo []) then {
                _target = getPosATL _uav;
                _target set [2, 0];
            };
        };
        private _grid = mapGridPosition _target;
        ["lase", [true, _target], format ["Lasing %1.", _grid]] call _fnc_order
    };
    case "rtb": {
        if !(call _fnc_may) exitWith {false};
        ([_uav] call EFUNC(devices,uavHome)) params ["_home", "_label"];
        private _lands = _uav isKindOf DRONES_LAND_KIND;
        ["rtb", [_home, DRONES_ORBIT_RADIUS], format [
            "RTB to %1 (%2), %3.", _label, mapGridPosition _home, ["will loiter", "will land"] select _lands
        ]] call _fnc_order
    };
    case "mode": {
        if (isNil QEFUNC(drone40,setMode)) exitWith {false};
        if (!_mine) then {
            ([_uav] call EFUNC(devices,uavCan)) params ["_ok", "_why"];
            if (!_ok) then {[_why] call _fnc_say};
            _mine = _ok;
        };
        if (!_mine) exitWith {false};
        private _ok = [_uav, _arg] call EFUNC(drone40,setMode);
        if (_ok) then {[format ["Drone40 mode: %1.", toUpper _arg], "normal"] call _fnc_say};
        _ok
    };
    case "mark": {
        private _at = uiNamespace getVariable [QGVAR(feedTarget), []];
        if (_at isEqualTo []) then {_at = getPosATL _uav; _at set [2, 0]};
        deleteMarkerLocal DRONES_MARK_NAME;
        private _m = createMarkerLocal [DRONES_MARK_NAME, _at];
        _m setMarkerTypeLocal DRONES_MARK_TYPE;
        _m setMarkerTextLocal format ["TGT %1", mapGridPosition _at];
        [format ["Target marked at %1.", mapGridPosition _at], "normal"] call _fnc_say;
        true
    };
    default {false};
};
