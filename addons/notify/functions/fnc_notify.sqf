#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_notify_fnc_notify

Description:
    Shows a notification locally. Takes a free slot if there is one, otherwise
    queues until FUNC(tick) frees one - the stack never grows past the player's
    Max on screen setting.

    With the addon disabled it falls back to a plain hint, so callers never have
    to check the setting themselves.

Parameters:
    _title  : STRING - short heading, shown in the accent colour.
    _text   : STRING - body line. Optional, default "".
    _colour : ARRAY  - RGBA accent for the bar and heading. Optional, default ember.

Returns:
    BOOL - true if it was shown or queued.

Example:
    ["Patrol Base", "Base established.", [0.91, 0.65, 0.24, 1]] call jmfsb_notify_fnc_notify

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_title", "", [""]], ["_text", "", [""]], ["_colour", [0.871, 0.361, 0.188, 1], [[]], 4], ["_pos", [], [[]]]];

if (!hasInterface) exitWith { false };

// Kept for the reader's LOG view whether the popup is enabled or not - the log
// is the record of what was said, and a hint fallback is still something said.
GVAR(history) pushBack [_title, _text, _colour, time, _pos];
if (count GVAR(history) > HISTORY_MAX) then { GVAR(history) deleteAt 0 };

// Hidden: recorded above, said nowhere.
if (GVAR(hidden)) exitWith { true };

if (!GVAR(enabled)) exitWith {
    hint format ["%1%2%3", _title, [": ", ""] select (_text isEqualTo ""), _text];
    true
};

// The display is created on first use, not at postInit, so a player who never
// gets a notification never carries the layer.
private _display = uiNamespace getVariable [QGVAR(hud), displayNull];
if (isNull _display) then {
    QGVAR(hud) cutRsc [QGVAR(hud), "PLAIN", 0, false];
    _display = uiNamespace getVariable [QGVAR(hud), displayNull];
};
if (isNull _display) exitWith { false };

if (count GVAR(slots) >= (GVAR(maxVisible) min SLOT_COUNT)) exitWith {
    GVAR(queue) pushBack [_title, _text, _colour];
    true
};

[_display, _title, _text, _colour] call FUNC(show);
true
