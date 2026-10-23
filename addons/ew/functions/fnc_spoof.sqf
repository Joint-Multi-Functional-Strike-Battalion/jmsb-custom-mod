#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: one man's GPS against the spoofers (DESIGN_EW "GPS spoof"). Inside
 * an enemy spoofer's field - or while his net is spoofed by a hack
 * (FUNC(spoofNode)) - an unprotected GPS is walked off its true position,
 * SPOOF_RATE_MPS along a heading rolled when it started, up to the drift
 * setting, and reads SPOOFED; outside it walks back twice as fast and reads
 * GOOD again at zero. An anti-spoof set (the EW Receiver) does not follow: it
 * reads SUSPECT, and a player is warned once per field.
 *
 * Players and AI alike: a player is kept by his UID (FUNC(publish) calls this
 * for him every DF tick), an AI man by his hash while he is off true
 * (FUNC(spoofTick)). The state and offset are hung on the man (QGVAR(gps),
 * public, on a 10 m grid, only when they change) so every machine draws his
 * BFT dot where his GPS says (FUNC(gpsOf)) and his DF cuts are plotted from
 * there (FUNC(tick)).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Seconds since the last call <NUMBER>
 *
 * Return Value:
 * [state, [dx, dy] m] <ARRAY>
 *
 * Example:
 * [_unit, 3] call jmfsb_ew_fnc_spoof
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_dt", 0, [0]]];

private _player = isPlayer _unit;
private _key = [hashValue _unit, getPlayerUID _unit] select _player;
private _side = str side group _unit;
private _pos = getPosASL _unit;
private _now = CBA_missionTime;

// A HACKED NET first: its whole group is in the field while the hack lasts.
private _inField = ((GVAR(spoofNodes) getOrDefault [hashValue group _unit, [grpNull, -1]]) select 1) > _now;
if (!_inField) then {
    {
        if ((_y get "tx") && (_y get "mode") isEqualTo MODE_SPOOF && (_y get "side") isNotEqualTo _side
            && alive (_y get "host") && (_pos distance2D (_y get "host")) <= (_y get "radius")) exitWith {
            _inField = true;
        };
    } forEach GVAR(jammers);
};

(GVAR(spoof) getOrDefault [_key, [0, random 360, false]]) params ["_mag", "_dir", "_told"];
private _state = GPS_GOOD;

if (_inField && {([_unit] call FUNC(kit)) get "receiver"}) then {
    _mag = 0;
    _state = GPS_SUSPECT;
    if (!_told) then {
        _told = true;
        [_unit, THREAT_SPOOFER, "GPS SUSPECT - A SPOOFER IS PULLING THE FIX", "NAVIGATE BY MAP AND COMPASS, DF THE SPOOFER"] call FUNC(warn);
    };
} else {
    if (_inField) then {
        _mag = (_mag + SPOOF_RATE_MPS * _dt) min GVAR(spoofDrift);
    } else {
        _mag = (_mag - SPOOF_RATE_MPS * SPOOF_DECAY_MULT * _dt) max 0;
        _told = false;
    };
    if (_mag > 0) then {_state = GPS_SPOOFED};
};
if (_mag <= 0 && !_inField) then {_dir = random 360};

// An AI man back on true and out of every field is forgotten; a player is
// kept (his heading and warning survive a respawn, as before).
if (!_player && _mag <= 0 && _state isEqualTo GPS_GOOD) then {
    GVAR(spoof) deleteAt _key;
} else {
    GVAR(spoof) set [_key, [_mag, _dir, _told, _unit, _player]];
};

private _offset = [round (_mag * sin _dir), round (_mag * cos _dir)];
private _shown = [_state, _offset apply {round (_x / SLICE_GRID_M) * SLICE_GRID_M}];
if ((_unit getVariable [QGVAR(gps), [GPS_GOOD, [0, 0]]]) isNotEqualTo _shown) then {
    _unit setVariable [QGVAR(gps), _shown, true];
};
[_state, _offset]
