#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a drone40 variant is up, or its mode was switched (FUNC(setMode)).
 * Its role is its mode (GVAR(mode), public on the drone) when one was set,
 * else its round's (GVAR(role) in config); in mode "off" nothing is
 * registered. By its role:
 *
 *   relay  - an RF node, profile droneRelay, holding the launcher's own fill
 *            (every net and key his nodes hold), so it relays his side's mesh
 *            from where it flies.
 *   decoy  - an RF node, profile handheld, claiming the launcher's nets under
 *            a key nobody else holds: it emits like a handheld, decodes
 *            nothing, relays nothing, and carries intent "decoy" in its
 *            node's data field for EW. No gameplay effect until EW reads it.
 *   jammer - no node; FUNC(noise) prices its barrage in RF. With jmfsb_ew
 *            loaded it is also an EW emitter (jmfsb_ew_fnc_addEmitter), so ES
 *            can DF it.
 *
 * With no launcher, or a launcher who holds no node, the fill is RF's DATA net.
 * The holder is the launcher, so his client gets the node's slice. The
 * launcher is kept on the drone (server only) for the next mode switch, and
 * where he stood is the drone's home for RTB (jmfsb_devices_uavHome, public)
 * unless it has one.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Launcher (objNull = none) <OBJECT>
 *
 * Return Value:
 * Node id, "" when nothing was registered <STRING>
 *
 * Example:
 * [_drone, player] call jmfsb_drone40_fnc_deploy
 *
 * Public: No
 */

params [["_drone", objNull, [objNull]], ["_launcher", objNull, [objNull]]];

if (!isServer || {isNull _drone} || {!alive _drone}) exitWith {""};

private _cfgRole = getText (configOf _drone >> QGVAR(role));
if !(_cfgRole in ROLES) exitWith {""};

if (!isNull _launcher) then {_drone setVariable [QGVAR(launcher), _launcher]};
if ((_drone getVariable [QEGVAR(devices,uavHome), []]) isEqualTo []) then {
    _drone setVariable [QEGVAR(devices,uavHome), getPosATL ([_drone, _launcher] select (!isNull _launcher)), true];
};

if ((_drone getVariable [QGVAR(id), ""]) isNotEqualTo "") exitWith {""};

private _role = _drone getVariable [QGVAR(mode), _cfgRole];
if !(_role in ROLES) exitWith {""};
if ((_drone getVariable [QGVAR(mode), ""]) isNotEqualTo _role) then {
    _drone setVariable [QGVAR(mode), _role, true];
};

GVAR(nextId) = GVAR(nextId) + 1;
private _id = format [NODE_ID_FORMAT, GVAR(nextId)];
_drone setVariable [QGVAR(id), _id];
GVAR(drones) set [_id, [_drone, _role, true]];

private _sideNo = ((getNumber (configOf _drone >> "side")) max 0) min (count SIDES_BY_NUMBER - 1);
private _side = SIDES_BY_NUMBER select _sideNo;

if (_role isEqualTo ROLE_JAMMER) exitWith {
    // AN EW EMITTER TOO, when jmfsb_ew is loaded: ES hears, DFs and classes
    // it as a jammer. Its noise stays FUNC(noise)'s; EW drops it when the
    // drone is gone and treats it as dark while its battery is flat.
    if (!isNil QEFUNC(ew,addEmitter)) then {
        [_drone, JAMMER_BANDS, GVAR(jammerPower), INTENT_JAMMER, _side, _id] call EFUNC(ew,addEmitter);
    };
    TRACE_2("jammer up",_id,_drone);
    _id
};
private _fill = [_launcher] call FUNC(launcherNets);

if (_role isEqualTo ROLE_RELAY) then {
    if (_fill isEqualTo []) then {_fill = [[NET_DATA, ""]]};
    [_drone, PROFILE_RELAY, _fill, _id, OWNER_TAG, _launcher, _side] call EFUNC(rf,register);
} else {
    private _key = format [DECOY_KEY_FORMAT, _id];
    private _nets = [];
    {
        _nets pushBackUnique (_x select 0);
    } forEach _fill;
    if (_nets isEqualTo []) then {_nets = [NET_DATA]};
    // THE DECOY MARK, in the node's data field for EW to read.
    [
        _drone, PROFILE_DECOY, _nets apply {[_x, _key]}, _id, OWNER_TAG, _launcher, _side,
        [[INTENT_KEY, INTENT_DECOY]]
    ] call EFUNC(rf,register);
    [_id, [["relay", false], ["tx", false]]] call EFUNC(rf,setState);
};

TRACE_3("drone up",_id,_role,_fill);
_id
