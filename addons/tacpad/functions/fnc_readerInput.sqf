#include "script_component.hpp"
/*
 * Author: YonV
 * The reply box, made fresh and put on top.
 *
 * WHY IT IS MADE HERE AND NOT DECLARED. A control declared in the dialog is
 * created before every runtime one, and the reader draws its entire screen
 * as a runtime group over the whole dialog - so the declared edit sat under
 * that group and never received a single click. It could be positioned, it
 * could be read, it could be written to by script; it could not be typed
 * into, which is the only thing a reply box is for.
 *
 * WHY IT IS A CHILD OF THE CONTENT GROUP. It used to be ctrlCreate'd on the
 * display, last, on the theory that the newest control on a display is the
 * top one. It was not: a controls group draws all of its children above the
 * display-level controls around it, so the box sat under the very screen it
 * was made to answer and still took no input. It is created into the content
 * group now, exactly where the compose pane's edits - the ones that always
 * worked - are created, and it is the last control made in that group, so it
 * is the topmost thing in its own rectangle. It keeps IDC_RD_INPUT, so every
 * reader that already asks the display for that id still finds it.
 *
 * Arguments:
 * 0: Parent - the content group the box belongs to <CONTROL>
 * 1: Position relative to the parent [x, y, w, h] <ARRAY>
 * 2: Ink colour <ARRAY>
 * 3: Shown <BOOL> (optional, default true)
 *
 * Return Value:
 * The edit <CONTROL>
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_pos", [0, 0, 0, 0], [[]], 4],
    ["_ink", [1, 1, 1, 1], [[]], 4],
    ["_show", true, [true]]
];

if (isNull _parent) exitWith {controlNull};

// The one from the last draw goes first - two edits under one id is the
// engine handing back whichever it likes. A rebuilt content group takes the
// old one with it, so this is usually already controlNull.
private _old = (ctrlParent _parent) displayCtrl IDC_RD_INPUT;
if (!isNull _old) then {ctrlDelete _old};

private _ctrl = (ctrlParent _parent) ctrlCreate [QGVAR(input), IDC_RD_INPUT, _parent];
_ctrl ctrlSetPosition _pos;
_ctrl ctrlSetTextColor _ink;
_ctrl ctrlCommit 0;
_ctrl ctrlShow _show;
_ctrl ctrlEnable _show;

_ctrl
