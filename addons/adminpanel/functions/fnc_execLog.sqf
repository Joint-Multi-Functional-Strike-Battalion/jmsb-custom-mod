#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a line in the RETURN panel beside the code box.
 *
 * THIS IS THE HALF THE DEBUG CONSOLE WAS MISSING. Code went out and a
 * notification said it had been sent; what it returned, and whether it threw,
 * went nowhere. An admin running `count allUnits` on the server had no way to
 * see the number.
 *
 * Called locally by the code box, and remotely by admp_fnc_compileAndExec on
 * whichever machine actually ran the code - which is why it is public.
 *
 * Arguments:
 * 0: The line <STRING>
 * 1: Is it an error <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["server exec ok"] call jmfsb_adminpanel_fnc_execLog
 *
 * Public: Yes
 */

params [["_line", "", [""]], ["_bad", false, [false]]];

if (!hasInterface) exitWith {};

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

private _log = _display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_RETURN;
if (isNull _log) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];

// A returned value is worth reading in full and a log with forty of them in it
// is not, so the panel keeps the last thirty and the newest is selected - which
// is also what scrolls it into view.
while {lbSize _log > 30} do {_log lbDelete 0};

private _index = _log lbAdd _line;
_log lbSetColor [_index, [_ink, _accent] select _bad];
_log lbSetCurSel _index;
