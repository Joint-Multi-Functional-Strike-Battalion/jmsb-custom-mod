#include "script_component.hpp"
/*
 * Author: JMSB
 * How long ago a mission time was, in the two or three characters a reading's
 * source line has room for: 40S, 12M, 2H.
 *
 * Arguments:
 * 0: Mission time the thing happened (CBA_missionTime) <NUMBER>
 *
 * Return Value:
 * Age <STRING>
 *
 * Example:
 * [_at] call jmfsb_medic_fnc_age
 *
 * Public: No
 */

#define SECONDS_PER_MINUTE 60
#define SECONDS_PER_HOUR 3600

params [["_at", 0, [0]]];

private _age = (CBA_missionTime - _at) max 0;

switch (true) do {
    case (_age < SECONDS_PER_MINUTE): {format ["%1S", floor _age]};
    case (_age < SECONDS_PER_HOUR): {format ["%1M", floor (_age / SECONDS_PER_MINUTE)]};
    default {format ["%1H", floor (_age / SECONDS_PER_HOUR)]};
}
