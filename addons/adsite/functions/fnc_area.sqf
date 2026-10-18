#include "..\script_component.hpp"
/*
 * Author: JMSB
 * An alarm area, made the first time a unit is filed into it. Its loudspeakers
 * are found HERE, with one nearestObjects, and cached - never per salvo.
 *
 * Area: [unit keys, loudspeakers, last alarm time]
 *
 * Arguments:
 * 0: Area key <STRING>
 * 1: Where its first unit stands, ASL <ARRAY>
 *
 * Return Value:
 * The area <ARRAY>
 *
 * Example:
 * ["site_1", getPosASL _vehicle] call jmfsb_adsite_fnc_area
 *
 * Public: No
 */

params [["_key", "", [""]], ["_pos", [0, 0, 0], [[]]]];

private _area = GVAR(areas) get _key;
if (!isNil "_area") exitWith {_area};

_area = [[], nearestObjects [ASLToAGL _pos, ADS_SPEAKERS, ADS_SPEAKER_RANGE], -1e9];
GVAR(areas) set [_key, _area];
_area
