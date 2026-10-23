#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: where this man's GPS says he is, for anything that REPORTS his
 * position - CUR LOC in a report card, the compose pin, + GRID in a reply,
 * the TIC's location, CENTRE on the map. Spoofed: the false position, with
 * nothing said (the set does not know). SUSPECT: the held fix, and when
 * loud, a warning to check it. NO FIX: nothing, and when loud, a warning to
 * read the grid off the map.
 *
 * Arguments:
 * 0: Say so on the notify rail when the fix is missing or suspect (optional, default false) <BOOL>
 *
 * Return Value:
 * GPS position ATL, [] when there is no fix <ARRAY>
 *
 * Example:
 * private _at = [true] call jmfsb_ew_fnc_gpsHere;
 *
 * Public: Yes
 */

params [["_loud", false, [false]]];

if (!hasInterface || isNull player) exitWith {[]};

([] call FUNC(gpsState)) params ["_state", "_offset"];

if (_state isEqualTo GPS_NOFIX) exitWith {
    if (_loud) then {[GPS_NOTE_TITLE, GPS_NOFIX_NOTE, THREAT_COLOUR] call EFUNC(notify,notify)};
    []
};
if (_loud && _state isEqualTo GPS_SUSPECT) then {
    [GPS_NOTE_TITLE, GPS_SUSPECT_NOTE, THREAT_COLOUR] call EFUNC(notify,notify);
};

(getPosATL player) vectorAdd [_offset select 0, _offset select 1, 0]
