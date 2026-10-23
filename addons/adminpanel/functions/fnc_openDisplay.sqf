#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens one of this addon's screens - the console, the message box, TIME /
 * WEATHER - where it belongs.
 *
 * ON A TABLET IT IS A CHILD OF THE TABLET (user, 2026-10-21: the console
 * "opens without the tablet frame"). A dialog opened over another dialog
 * becomes the top of the stack and the engine stops drawing the one under it,
 * so the device vanished round the console. A child display (createDisplay on
 * the tablet) is drawn over its parent with the parent still showing, and
 * FUNC(fitHost) lays it on the tablet's screen. A screen opened from the
 * console is the console's child the same way. With no device up it is the
 * dialog it always was.
 *
 * Arguments:
 * 0: Dialog class <STRING>
 * 1: Parent display <DISPLAY> (optional, default: the open device, else none)
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [QGVAR(console)] call jmfsb_adminpanel_fnc_openDisplay
 *
 * Public: No
 */

params [["_class", "", [""]], ["_parent", displayNull, [displayNull]]];

if (_class isEqualTo "") exitWith {false};
if (isNull _parent && HOST_DEVICE) then {_parent = HOST_DISPLAY};
if (isNull _parent) exitWith {createDialog _class};
!isNull (_parent createDisplay _class)
