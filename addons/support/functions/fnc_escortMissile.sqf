#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a missile is coming at an escorted lead or at one of its escorts
 * (DESIGN_SUPPORT_MESSAGING 1.2, user, 2026-11-01: "defend and protect").
 * Every escort of that lead puts out its own flares (FUNC(escortFlare)), and
 * so does the lead when an AI flies it - a decoy beside the lead pulls a seeker
 * as well as one from the lead itself. Whoever fired becomes the escorts'
 * first target (FUNC(escortTick)).
 *
 * Raised by the IncomingMissile handler FUNC(escort) puts on the lead and the
 * escorts, and by the watch's own missile scan. Quiet for an aircraft with no
 * live escort.
 *
 * Arguments:
 * 0: The aircraft the missile is coming at <OBJECT>
 * 1: Who fired it <OBJECT> (optional, default objNull)
 *
 * Return Value:
 * Aircraft that flared <NUMBER>
 *
 * Example:
 * [_veh, _shooter] call jmfsb_support_fnc_escortMissile
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_shooter", objNull, [objNull]]];

if (!isServer || {isNull _target}) exitWith {0};

private _lead = _target getVariable [QGVAR(escortOf), _target];
if (isNull _lead) exitWith {0};
private _escorts = (_lead getVariable [QGVAR(escorts), []]) select {alive _x};
if (_escorts isEqualTo []) exitWith {0};

if (alive _shooter) then {
    _lead setVariable [QGVAR(escortShooter), [_shooter, CBA_missionTime]];
};

private _flaring = +_escorts;
if (alive _lead && !isPlayer driver _lead) then {_flaring pushBack _lead};

private _flared = {[_x] call FUNC(escortFlare)} count _flaring;
if (_flared > 0) then {
    INFO_3("'%1' under missile fire from '%2' - %3 aircraft flared",typeOf _target,typeOf _shooter,_flared);
    // Said in the lead's thread, once per EVENT_REPEAT_S (user, 2026-11-05).
    if (CBA_missionTime - (_lead getVariable [QGVAR(missileSaidAt), -EVENT_REPEAT_S]) >= EVENT_REPEAT_S) then {
        _lead setVariable [QGVAR(missileSaidAt), CBA_missionTime];
        [EVENT_AIRCRAFT, [_lead, EVENT_MISSILE_TEXT, true]] call CBA_fnc_localEvent;
    };
};

_flared
