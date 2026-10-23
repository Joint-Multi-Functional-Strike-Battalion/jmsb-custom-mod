#include "script_component.hpp"
/*
 * Author: JMSB
 * Closes the TAC//MSG reader wherever it is: the reader dialog on the vanilla
 * map, or the reader drawn inside the tablet (FUNC(openReader)), which is the
 * open app there and closes as every app does - FUNC(appClose) - leaving the
 * device up. Closing the device dialog in its place would take the whole
 * tablet down with the reader.
 *
 * The in-tablet close is a frame late: CLOSE is a control in the reader's own
 * root, and the close deletes that root.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something was closed <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_readerClose
 *
 * Public: Yes
 */

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {false};

if ((uiNamespace getVariable [QGVAR(appCurrent), ""]) isEqualTo READER_APP && {_display isEqualTo (HOST_DISPLAY)}) exitWith {
    [{
        if ((uiNamespace getVariable [QGVAR(appCurrent), ""]) isEqualTo READER_APP) then {
            [] call FUNC(appClose);
        };
    }] call CBA_fnc_execNextFrame;
    true
};

_display closeDisplay 0;
true
