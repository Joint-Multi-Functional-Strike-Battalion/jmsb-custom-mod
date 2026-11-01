#include "script_component.hpp"
/*
 * Author: JMSB
 * What every device's header bar says - the tablet's (FUNC(tabletBar)) and
 * the phone's and side devices' (FUNC(overlayDraw); user, 2026-10-21: "the
 * devices still need some kind of header bar with info"). One answer, so the
 * bars cannot disagree:
 *
 *   clock     mission time (jmfsb_tacpad_fnc_clock)
 *   grid      the GPS's grid, 8 or 10 figures (FUNC(overlayGrid))
 *   gps       "" good, GPS_STATE_SUSPECT or GPS_STATE_NOFIX
 *   who       "NAME . GROUP"
 *   channels  the custom-channel gauge, "" for none (FUNC(channelText))
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Facts <HASHMAP>
 *
 * Example:
 * private _facts = [] call jmfsb_devices_fnc_deviceFacts
 *
 * Public: No
 */

private _unit = call CBA_fnc_currentUnit;
([] call FUNC(overlayGrid)) params ["_grid", "_gps"];

createHashMapFromArray [
    ["clock", [CBA_missionTime] call EFUNC(tacpad,clock)],
    ["grid", _grid],
    ["gps", _gps],
    ["who", format ["%1 %2 %3", toUpper name _unit, MIDDOT, toUpper groupId group _unit]],
    ["channels", [] call FUNC(channelText)],
    // Point Man's next waypoint while a route is walked, "" otherwise.
    ["nav", if (isNil QEFUNC(pointman,navText)) then {""} else {[] call EFUNC(pointman,navText)}],
    // The handheld's battery (jmfsb_voice_fnc_batteryLevel), "" without a set
    // (user, 2026-10-30: "the battery % on the tablet ... needs to work").
    ["batt", if (isNil QEFUNC(voice,batteryLevel)) then {""} else {
        private _level = [] call EFUNC(voice,batteryLevel);
        if (_level < 0) then {""} else {format ["BATT %1%2", round (_level * PERCENT), "%"]}
    }]
]
