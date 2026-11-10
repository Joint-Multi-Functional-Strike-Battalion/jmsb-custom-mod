#include "script_component.hpp"
/*
 * Author: YonV
 * The WILCO a REQUEST ON STATION is answered with, by every air provider
 * (user, 2026-11-02: "on station is not a fire mission its just an order to
 * get in the air"): LAUNCHING, then when it is there - "LAUNCHING - ON STATION
 * IN m:ss"; "LAUNCHING" alone when nobody can say. FUNC(srvReply) puts ROGER,
 * WILCO in front of it.
 *
 * Arguments:
 * 0: Seconds until it is on station, -1 unknown <NUMBER>
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [160] call jmfsb_support_fnc_stationWilco
 *
 * Public: Yes
 */

params [["_seconds", ETA_UNKNOWN, [0]]];

private _when = [_seconds, STATION_ETA_WORD] call FUNC(etaText);

([STATION_LAUNCHING, _when] select {_x isNotEqualTo ""}) joinString STATION_WILCO_SEP
