#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player's active voice net, as a line short enough for a table
 * column - the squad table's RADIO, the target card, the HUD's fallback.
 *
 * GAME VOICE THROUGH ONE API (docs/DESIGN_VOICE.md). The net is the one
 * jmfsb_voice_fnc_netState marks active; no voice addon loaded is a state, not
 * a fault, and the column says nothing rather than inventing a net. Never a
 * frequency.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Net name, "" when there is no voice addon or no active net <STRING>
 *
 * Example:
 * private _net = [] call jmfsb_tacpad_apps_fnc_radioState
 *
 * Public: No
 */

if (!hasInterface || {isNil QEFUNC(voice,netState)}) exitWith {""};

private _nets = [] call EFUNC(voice,netState);
private _i = _nets findIf {_x param [3, false]};
if (_i < 0) exitWith {""};

(_nets select _i) param [1, ""]
