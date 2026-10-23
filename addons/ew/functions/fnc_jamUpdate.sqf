#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: works out whether a jammer is ON THE AIR ("tx") and keeps what
 * follows from it in step. Switched on is not enough - it transmits only
 * while its battery is not flat, it is not in thermal cutout (both kept on the
 * host by FUNC(jamPower)), and, on AUTO, while FUNC(jamAuto) has it engaged.
 * Everything that radiates reads "tx": the noise (FUNC(noise)), the emitter ES
 * hears (FUNC(collect)), spoof and the spot warning.
 *
 * GPS lays a jamming-addon zone (GPS domain) on the host while it transmits;
 * the zone goes when it stops or its radius changes.
 *
 * Arguments:
 * 0: Jammer <HASHMAP>
 *
 * Return Value:
 * A refusal to tell the operator, "" when none <STRING>
 *
 * Example:
 * [_j] call jmfsb_ew_fnc_jamUpdate
 *
 * Public: No
 */

params [["_j", createHashMap, [createHashMap]]];

if (count _j == 0) exitWith {""};

private _host = _j get "host";
(_host getVariable [QGVAR(power), JAM_POWER_FRESH]) params ["", "", ["_flat", false], ["_cutout", false]];
private _was = _j getOrDefault ["tx", false];
private _tx = (_j get "on") && {!isNull _host} && {alive _host} && {!_flat} && {!_cutout}
    && {(_j get "operation") isEqualTo OP_CONTINUOUS || {_j get "engaged"}};
_j set ["tx", _tx];

private _refuse = "";
private _zone = _j get "zone";
if (_zone isNotEqualTo "" && {!_tx || {(_j get "mode") isNotEqualTo MODE_GPS} || {(_j get "zoneR") isNotEqualTo (_j get "radius")}}) then {
    if (!isNil QEFUNC(jamming,removeZone)) then {[_zone] call EFUNC(jamming,removeZone)};
    _j set ["zone", ""];
};
if (_tx && {(_j get "mode") isEqualTo MODE_GPS} && {(_j get "zone") isEqualTo ""}) then {
    if (isNil QEFUNC(jamming,zoneOnObject)) exitWith {_refuse = "GPS JAMMING NEEDS THE JAMMING ADDON"};
    _j set ["zone", [_host, _j get "radius", JAM_ZONE_DOMAINS, OWNER_TAG] call EFUNC(jamming,zoneOnObject)];
    _j set ["zoneR", _j get "radius"];
};

if (_tx && !_was) then {
    [QGVAR(jamOn), [_j get "id", _j get "mode", _j get "side"]] call CBA_fnc_localEvent;
};

_refuse
