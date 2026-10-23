#include "script_component.hpp"
/*
 * Author: JMSB
 * The DRONES board's fleet: every live UAV on the players' side, with what the
 * board shows of it. Read from the engine and from RF, never computed:
 *
 * SIDE. The players' side, derived (D59): the player's own side when it is one
 * of the sides players hold (jmfsb_common_fnc_playerSides), else the first of
 * them - the same derivation the CAS controller uses.
 *
 * LINK. A drone is flown over the DATA net (DESIGN_TABLET_APPS.md, DRONES:
 * "Control needs the DATA link"), so the link is RF's DATA quality for the
 * operator's own sets (FUNC(radioRfQuality)); below DRONE_LINK_LOST control is
 * lost (DESIGN_RF.md). Jamming that reaches drones is the jamming addon's own
 * number at the drone (jmfsb_jamming_fnc_jamFactor, its UAV domain), shown
 * beside it, not folded into it.
 *
 * WHOSE. There is no vanilla UAV terminal (user, 2026-10-20), so "linked to
 * me", the operator and "can connect" are the devices' own drone link
 * (jmfsb_devices_fnc_uavControl / uavOperator / uavCan); without that addon
 * nobody can connect.
 *
 * LASE. Whether the airframe carries a designator
 * (jmfsb_devices_fnc_uavLaser) and whether it is lasing - the point its
 * owner publishes (jmfsb_devices_uavLase, jmfsb_devices_fnc_uavOrder).
 *
 * MODE. A Drone40 variant's mode (jmfsb_drone40_mode, public; its round's
 * role until switched), "" for any other drone or without that addon.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows, each [uav, name, link word, quality (QUALITY_UNKNOWN when RF cannot
 * say), battery 0..1, task, linked to me, operator ("" none), can connect,
 * jam 0..1, why not ("" when he can), lasing, has a laser, Drone40 mode
 * ("" not one)] <ARRAY>
 *
 * Example:
 * private _fleet = [] call jmfsb_tacpad_apps_fnc_appDronesData
 *
 * Public: No
 */

private _sides = call EFUNC(common,playerSides);
private _side = side group player;
if (_sides isNotEqualTo [] && {!(_side in _sides)}) then {_side = _sides select 0};

private _q = [RADIO_NET_DATA] call FUNC(radioRfQuality);
private _devices = !isNil QEFUNC(devices,uavControl);
private _mine = if (_devices) then {["linked"] call EFUNC(devices,uavControl)} else {objNull};
private _jamOk = !isNil QEFUNC(jamming,jamFactor);
private _d40 = !isNil QEFUNC(drone40,setMode);

private _out = [];
{
    private _uav = _x;
    private _operator = if (_devices) then {[_uav] call EFUNC(devices,uavOperator)} else {objNull};
    private _flown = _uav getVariable [QEGVAR(devices,uavFlown), false];
    (if (_devices) then {[_uav] call EFUNC(devices,uavCan)} else {
        [false, "Drone control needs the JMSB devices addon."]
    }) params ["_can", "_why"];

    private _jam = if (_jamOk) then {
        ([getPosASL _uav, 0, DRONES_JAM_DOMAIN] call EFUNC(jamming,jamFactor)) param [0, 0]
    } else {0};

    private _word = switch (true) do {
        case (_q < 0): {"NO RF"};
        case (_q < DRONE_LINK_LOST): {"LOST"};
        case (_jam > 0): {format ["JAM %1%2", round (_jam * PERCENT), "%"]};
        default {"DATA"};
    };

    private _role = if (_d40) then {getText (configOf _uav >> QEGVAR(drone40,role))} else {""};
    private _mode = if (_role isEqualTo "") then {""} else {_uav getVariable [QEGVAR(drone40,mode), _role]};

    // TASK: who flies it, who links it, else what its group was told.
    private _grp = group _uav;
    private _wps = waypoints _grp;
    private _wp = currentWaypoint _grp;
    private _task = switch (true) do {
        case (!isNull _operator && _flown): {format ["MANUAL - %1", toUpper name _operator]};
        case (!isNull _operator): {format ["LINKED - %1", toUpper name _operator]};
        case (_wp < count _wps): {toUpper (waypointType [_grp, _wp])};
        default {"HOLDING"};
    };

    _out pushBack [
        _uav,
        toUpper getText (configOf _uav >> "displayName"),
        _word,
        _q,
        fuel _uav,
        _task,
        _uav isEqualTo _mine,
        [name _operator, ""] select (isNull _operator),
        _can,
        _jam,
        _why,
        (_uav getVariable [QEGVAR(devices,uavLase), []]) isNotEqualTo [],
        _devices && {([_uav] call EFUNC(devices,uavLaser)) isNotEqualTo []},
        _mode
    ];
} forEach (allUnitsUAV select {alive _x && {(side group _x) isEqualTo _side}});

_out
