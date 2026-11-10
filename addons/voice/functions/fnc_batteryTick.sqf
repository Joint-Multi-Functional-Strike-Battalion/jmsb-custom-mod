#include "script_component.hpp"
/*
 * Author: YonV
 * Client, on the client tick: says when the handheld's battery crosses one
 * of BATTERY_WARN_LEVELS on the way down - once per level, with how many
 * spares he carries - and when it is flat. A swap or a charge above the
 * level arms the warning again.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_batteryTick
 *
 * Public: No
 */

private _level = [] call FUNC(batteryLevel);
if (_level < 0) exitWith {};

// The lowest warning level the battery is at or under, -1 above them all.
private _at = -1;
{
    if (_level <= _x) then {_at = _forEachIndex};
} forEach BATTERY_WARN_LEVELS;

if (_at isEqualTo GVAR(batteryWarned)) exitWith {};
GVAR(batteryWarned) = _at;
if (_at < 0) exitWith {};

private _spares = count ([] call FUNC(batterySpares));
private _text = if (_level <= 0) then {
    format ["Radio battery flat - no nets. %1 spare%2.", _spares, ["s", ""] select (_spares isEqualTo 1)]
} else {
    format ["Radio battery %1%2. %3 spare%4 - swap it from the RADIO app.", round (_level * PERCENT), "%", _spares, ["s", ""] select (_spares isEqualTo 1)]
};
[BLOCK_TITLE, _text] call EFUNC(notify,notify);
