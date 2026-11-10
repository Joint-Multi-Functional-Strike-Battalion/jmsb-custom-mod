#include "script_component.hpp"
/*
 * Author: YonV
 * A live screen's tick (code review R8): when its shape is the one it was built
 * with (FUNC(liveStore)) and every control is still there, the new values go
 * into those controls - words and colours only, nothing deleted, nothing
 * moved, so a press on the screen is never lost to its own refresh. Anything
 * else answers false and the caller builds the screen again, as it always
 * did.
 *
 * Arguments:
 * 0: Holder - the screen's group or body <CONTROL>
 * 1: Shape, as the full draw would work it out now <ANY>
 * 2: Values [[text, RGBA], ...], one per stored entry, in order <ARRAY>
 *
 * Return Value:
 * Updated in place - false means build it again <BOOL>
 *
 * Example:
 * if ([_group, _shape, _values] call jmfsb_tacpad_fnc_liveApply) exitWith {}
 *
 * Public: Yes
 */

params [["_holder", controlNull, [controlNull]], ["_shape", []], ["_values", [], [[]]]];

if (isNull _holder) exitWith {false};

(_holder getVariable [QGVAR(live), ["", []]]) params ["_key", "_entries"];
if (_key isNotEqualTo str _shape) exitWith {false};
if ((count _entries) isNotEqualTo (count _values)) exitWith {false};
if ((_entries findIf {((_x select 0) findIf {isNull _x}) >= 0}) >= 0) exitWith {false};

{
    _x params ["_ctrls", "_style"];
    (_values select _forEachIndex) params [["_text", "", [""]], ["_colour", [0, 0, 0, 0], [[]]]];
    if (_style isEqualTo []) then {
        {_x ctrlSetBackgroundColor _colour} forEach _ctrls;
    } else {
        ([_ctrls select 0, _text, _colour] + _style) call FUNC(retext);
    };
} forEach _entries;

true
