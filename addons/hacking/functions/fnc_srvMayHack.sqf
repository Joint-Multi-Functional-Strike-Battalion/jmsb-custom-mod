#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: may this man hack this device as this kind, now - the server's own
 * answer to what the client's tablet already decided (review S7). Every fact
 * is read here: the operator's gate (FUNC(canHack)), his distance to the
 * device against the kind's range, that the device is what the kind says (the
 * same tests the scan makes - FUNC(towersInRange), FUNC(nearestDrone),
 * FUNC(nearestWreck), FUNC(scanDevices), FUNC(rfReach)), and the server's own
 * ledger of what is already broken and when each tower was last hacked. The
 * ledger is in localNamespace: the public flags on the devices are for
 * screens, and any client can write them.
 *
 * Arguments:
 * 0: The operator - the sender's own unit, never one from the request <OBJECT>
 * 1: The device <OBJECT>
 * 2: Kind, "tower" | "drone" | "wreck" | "unit" <STRING>
 *
 * Return Value:
 * Why not, "" when he may <STRING>
 *
 * Example:
 * [_unit, _device, "tower"] call jmfsb_hacking_fnc_srvMayHack
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_device", objNull, [objNull]], ["_kind", "", [""]]];

if (isNull _unit || {!alive _unit}) exitWith {"no operator"};
if (isNull _device) exitWith {"no device"};
if !([_unit] call FUNC(canHack)) exitWith {"not cleared to hack"};

private _mySide = side group _unit;
private _dist = _unit distance _device;
private _done = localNamespace getVariable [QGVAR(srvDone), createHashMap];
private _allowed = (GVAR(droneClasses) splitString ", ") select {_x != ""};
private _fnc_classAllowed = {_allowed isEqualTo [] || {_allowed findIf {_device isKindOf _x} > -1}};

if (_kind isEqualTo "tower") exitWith {
    private _range = [QGVAR(cfg_hack_range)] call FUNC(hackSetting);
    if (_dist > _range + HACK_SERVER_RANGE_PAD) exitWith {"out of range"};
    if !(_device in ([_unit, _range + HACK_SERVER_RANGE_PAD] call FUNC(towersInRange))) exitWith {"not a device the suite can break"};
    // Towers hold a cooldown; -1 makes them one-shot - the server's own record.
    private _cd = [QGVAR(cfg_hack_cooldown)] call FUNC(hackSetting);
    private _towers = localNamespace getVariable [QGVAR(srvTowerAt), createHashMap];
    private _key = _device call BIS_fnc_netId;
    if (_key in _towers && _cd < 0) exitWith {"that tower is spent"};
    if (_key in _towers && {(CBA_missionTime - (_towers get _key)) < _cd}) exitWith {"that tower is cooling down"};
    ""
};

if (_kind isEqualTo "drone") exitWith {
    if (_dist > HACK_DRONE_RANGE + HACK_SERVER_RANGE_PAD) exitWith {"out of range"};
    // The side off the crew, as FUNC(nearestDrone) reads it.
    private _crew = crew _device;
    private _theirSide = if (_crew isEqualTo []) then {side _device} else {side (_crew select 0)};
    if !(
        alive _device
        && {getNumber (configOf _device >> "isUav") > 0}
        && {_theirSide in [east, west, resistance]}
        && {_theirSide getFriend _mySide < HACK_HOSTILE_BELOW}
        && {call _fnc_classAllowed}
    ) exitWith {"not a hostile drone"};
    if ((_device call BIS_fnc_netId) in _done) exitWith {"that drone is already down"};
    ""
};

if (_kind isEqualTo "wreck") exitWith {
    if (_dist > HACK_WRECK_RANGE + HACK_SERVER_RANGE_PAD) exitWith {"out of range"};
    // As FUNC(nearestWreck): an unknown side is fair game, our own is not.
    if !(
        !alive _device
        && {getNumber (configOf _device >> "isUav") > 0}
        && {!((side group _device) in [_mySide, sideFriendly])}
        && {call _fnc_classAllowed}
    ) exitWith {"not a downed drone"};
    if ((_device call BIS_fnc_netId) in _done) exitWith {"that wreck is already stripped"};
    ""
};

if (_kind isEqualTo "unit") exitWith {
    if !(GVAR(remoteEnable)) exitWith {"remote hacking is off"};
    private _range = missionNamespace getVariable [QGVAR(rh_max_range), RH_RANGE_DEF];
    if (_dist > _range + HACK_SERVER_RANGE_PAD) exitWith {"out of range"};
    // A net is a group: a man's handset, or the crew of a vehicle carrying a set.
    private _isMan = _device isKindOf "CAManBase";
    private _boss = [effectiveCommander _device, _device] select _isMan;
    if (!alive _device || {isNull _boss} || {!alive _boss}) exitWith {"no net there"};
    private _grp = group _boss;
    if (_grp isEqualTo (group _unit)) exitWith {"that is your own net"};
    private _theirSide = side _grp;
    private _hostile = _theirSide getFriend _mySide < HACK_HOSTILE_BELOW;
    private _civ = _theirSide isEqualTo civilian;
    private _inScope = switch (GVAR(netTargets)) do {
        case 1: {_hostile || _civ};
        case 2: {true};
        default {_hostile && {!_civ}};
    };
    if (!_inScope) exitWith {"not a net the mission lets you break"};
    if ((_grp call BIS_fnc_netId) in _done) exitWith {"that net is already broken"};
    if (_isMan) exitWith {
        ["no handset on him", ""] select (isNull objectParent _device && {[_device] call FUNC(hasPhone)})
    };
    // A vehicle is a net only when RF says the operator's set hears it.
    if ((([_unit] call FUNC(rfReach)) findIf {(_x param [0, objNull]) isEqualTo _device}) < 0) exitWith {"no set in reach there"};
    ""
};

"not a device the suite can break"
