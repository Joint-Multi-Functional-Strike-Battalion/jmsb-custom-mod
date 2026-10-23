#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: what a track is called on this man's screen (DESIGN_EW "Identify",
 * "Player skill"). A named track (his side holds the key) shows its net and
 * set to anyone. Otherwise the class: an ISR player reads every class; anyone
 * else reads only what the energy itself gives away - a jammer, a spoofer, a
 * drone's video - and UNKNOWN for the rest.
 *
 * Arguments:
 * 0: Track, in the slice's layout (FUNC(publish)) <ARRAY>
 * 1: Is ISR <BOOL>
 *
 * Return Value:
 * Label <STRING>
 *
 * Example:
 * [_track, true] call jmfsb_ew_fnc_classShown
 *
 * Public: No
 */

params [["_track", [], [[]]], ["_isr", false, [false]]];

_track params ["", "", "", ["_class", CLASS_UNKNOWN], ["_named", ""]];
if (_named isNotEqualTo "") exitWith {_named};
if (_isr || {_class in [CLASS_JAM, CLASS_SPOOF, CLASS_VIDEO]}) exitWith {_class};
CLASS_UNKNOWN
