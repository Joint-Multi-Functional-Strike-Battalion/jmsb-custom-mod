#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the reader's right pane into compose. Opens the reader first if it is not
 * already up, so NEW off the docked rail lands on the same screen as NEW off the
 * full one.
 *
 * IT IS NOT A WINDOW. Composing used to be a second dialog over the top of the
 * reader, which put the thread being answered behind the answer and made
 * sending a report an act that closed the traffic it was about. The pane the
 * thread was in is the pane the reply is written in.
 *
 * THE MESSAGE IS THE DEFAULT. Opening with no template gives a plain message
 * box; a report is INSERTED from there with the TEMPLATE button. It opened on an
 * empty picker before - a screen that would not let you type a word until you
 * had chosen a form.
 *
 * Arguments:
 * 0: Thread to reply into, "" for a new message <STRING> (optional, default "")
 * 1: Template to open with, "" for the plain message box <STRING> (optional, default "")
 * 2: Open on the template picker <BOOL> (optional, default false)
 * 3: Addressees for a new message, "" for the current net <STRING> (optional, default "")
 * 4: Answers to start with, as [key, value] pairs <ARRAY> (optional, default [])
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["", "", true] call jmfsb_tacpad_fnc_composeOpen
 *
 * Public: Yes
 */

params [
    ["_threadId", "", [""]],
    ["_templateId", "", [""]],
    ["_pick", false, [false]],
    ["_to", "", [""]],
    ["_values", [], [[]]]
];

if (!hasInterface) exitWith {false};

if (isNil QEFUNC(messaging,templateIds)) exitWith {
    ["COMPOSE", "Messaging is not loaded.", "high"] call EFUNC(messaging,notify);
    false
};

// THE SCREEN FIRST, THE STATE SECOND. Opening the reader clears compose - a
// reader opened from the keybind must never come up mid-message - so the state
// is set after it, not before.
if (isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
    [] call FUNC(openReader);
};

if (isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) exitWith {false};

GVAR(composeOn) = true;
GVAR(composeThread) = _threadId;
GVAR(composeTemplate) = _templateId;
GVAR(composePick) = _pick;
GVAR(composeToPick) = false;
GVAR(composeValues) = createHashMap;
GVAR(composeGridText) = createHashMap;
GVAR(composeMarker) = "";
GVAR(composePin) = [];

GVAR(composePinPick) = false;
GVAR(composeTo) = _to;
GVAR(composeCc) = "";
GVAR(composeTags) = "";
GVAR(composeError) = "";
GVAR(composeMissing) = [];

// An answer handed in by whatever opened this - the casualty a CASEVAC is being
// filed for, say. A position is shown as its grid, exactly as CURRENT LOC shows
// one, so the player can see and overtype what was put in for them.
{
    _x params [["_key", "", [""]], "_value"];
    if (_key isEqualTo "" || {isNil "_value"}) then {continue};

    GVAR(composeValues) set [_key, _value];
    if (_value isEqualType [] && {count _value >= 2}) then {
        GVAR(composeGridText) set [_key, mapGridPosition _value];
    };
} forEach _values;

// The thread stays selected in the list while it is being replied to, so the
// player can see what they are answering.
GVAR(readerThread) = _threadId;

// NEXT FRAME. This is called from a button handler, and the redraw deletes the
// button whose handler is running.
{[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;

true
