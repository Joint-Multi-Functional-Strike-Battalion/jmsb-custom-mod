#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the drone escorts of one sortie (user, 2026-11-02: "drone escorts is
 * based on lz security for helos and always for fix wings"). Shared by every
 * support aircraft module - this addon's CAS, Transport and QRF,
 * support_logistics' and the jumpmaster's - which all write the same two Eden
 * attributes:
 *
 *   Fixed-Wing Escort Class (escortPlane) the drone a fixed-wing lead takes;
 *                                         empty - the side's vanilla UCAV
 *                                         (ESCORT_PLANE_DEFAULTS)
 *   Rotary Escort Class (escortHeli)      the drone a helicopter lead takes;
 *                                         empty - none
 *
 * A FIXED-WING LEAD takes two fixed-wing drones on every sortie, always.
 *
 * A HELICOPTER LEAD takes two rotary drones only when the request's LZ
 * security is YELLOW or RED (EFUNC(support,lzSecurity): the request card's
 * security line, from the asset's open thread in TAC//MSG). GREEN, a card
 * with no security line (`cas`, `qrf`, `airdrop`, a jump), none ticked, or no
 * thread: none. Read ESCORT_LZ_WAIT seconds after the launch.
 *
 * They are made with the lead, beside it over its module, fly with it and are
 * removed with it (the support core's escort watch). The old Drone Escorts
 * on/off attribute is retired (2026-11-02): a mission that set it still
 * loads, the value is not read.
 *
 * A CLASS THAT IS NOT ONE - not in this mission, or not the lead's kind - is
 * no escort, and one RPT warning per module and attribute.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The lead aircraft <OBJECT>
 * 2: The task point (target, area, LZ, drop), [] for none <ARRAY>
 * 3: The asset id, as the support core knows it ("air:2", "logi:0") <STRING>
 * 4: The players' side <SIDE>
 * 5: Called for (the ESCORT command, user 2026-11-09: "a way to call in escorts
 *    to all transports no mater the phase or tasking") - a helicopter takes
 *    its escorts whatever the LZ security <BOOL> (optional, default false).
 *    An ESCORT pressed before the aircraft was made (GVAR(escortWanted) on
 *    the module, FUNC(escortCall)) counts as called for, once.
 *
 * Return Value:
 * Escorts asked for <BOOL>
 *
 * Example:
 * [_logic, _veh, _pos, "air:2", west] call jmfsb_support_air_fnc_escortLaunch
 *
 * Public: Yes
 */

params [
    ["_logic", objNull, [objNull]],
    ["_lead", objNull, [objNull]],
    ["_point", [], [[]]],
    ["_assetId", "", [""]],
    ["_side", west, [west]],
    ["_force", false, [false]]
];

if (!isServer || {isNull _logic} || {!alive _lead}) exitWith {false};

if (_logic getVariable [QGVAR(escortWanted), false]) then {
    _force = true;
    _logic setVariable [QGVAR(escortWanted), nil];
};

private _heli = _lead isKindOf "Helicopter";
private _attr = ["escortPlane", "escortHeli"] select _heli;
private _kind = ["Plane", "Helicopter"] select _heli;
private _cls = _logic getVariable [_attr, ""];
if (_cls isEqualTo "" && !_heli) then {
    private _at = ESCORT_PLANE_SIDES find _side;
    if (_at > -1) then {_cls = ESCORT_PLANE_DEFAULTS select _at};
};
// A helicopter with no rotary class has no escort, and nothing to warn about.
if (_cls isEqualTo "") exitWith {false};

if (!isClass (configFile >> "CfgVehicles" >> _cls) || {!(_cls isKindOf _kind)} || {_cls isKindOf "ParachuteBase"}) exitWith {
    private _warned = _logic getVariable [QGVAR(escortWarned), []];
    if !(_attr in _warned) then {
        _warned pushBack _attr;
        _logic setVariable [QGVAR(escortWarned), _warned];
        WARNING_4("%1: %2 '%3' is not a %4 class in this mission - no escort",_assetId,_attr,_cls,_kind);
    };
    false
};

if (!_heli || _force) exitWith {
    [_lead, _cls, _side, _point] call EFUNC(support,escort);
    true
};

[{
    params ["_lead", "_cls", "_side", "_point", "_assetId"];
    if (!alive _lead) exitWith {};
    private _security = [_assetId] call EFUNC(support,lzSecurity);
    if !(_security in ESCORT_LZ_ESCORTED) exitWith {
        INFO_2("%1: LZ security '%2' - no escort",_assetId,_security);
    };
    INFO_2("%1: LZ security %2 - escorted",_assetId,_security);
    [_lead, _cls, _side, _point] call EFUNC(support,escort);
}, [_lead, _cls, _side, _point, _assetId], ESCORT_LZ_WAIT] call CBA_fnc_waitAndExecute;

true
