#include "script_component.hpp"
/*
 * Author: JMSB
 * Remembers what a live screen just built, so its tick can change the words
 * and colours in place instead of building it again (FUNC(liveApply); code
 * review R8). Called at the end of the full draw with the screen's shape -
 * everything that decides which controls exist and where - and its live
 * entries, in the order the screen's values come in.
 *
 * An entry is [controls, style]: a style of [] is a fill, whose background
 * colour is the value's; any other style is FUNC(retext)'s size, bold,
 * alignment, tracking and font for a line FUNC(drawText) made.
 *
 * Arguments:
 * 0: Holder - the screen's group or body <CONTROL>
 * 1: Shape <ANY>
 * 2: Entries [[controls <ARRAY of CONTROLs>, style <ARRAY>], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_group, _shape, _entries] call jmfsb_tacpad_fnc_liveStore
 *
 * Public: Yes
 */

params [["_holder", controlNull, [controlNull]], ["_shape", []], ["_entries", [], [[]]]];

_holder setVariable [QGVAR(live), [str _shape, _entries]];
