#include "script_component.hpp"
/*
    File: fnc_uiRefresh.sqf
    Author: YonV
    Description: Something the page reads was republished - the roster, the
        structure, the log. Redraw the page IF it is one that only reads: a
        table, the dashboard. A form being typed into is left alone, so a
        roster publish cannot wipe an admin's half-written note.

        A page says it is safe to redraw by setting GVAR(uiLive) true.

    Parameters:
        0: What changed <STRING> (optional, for the log)

    Returns:
        Nothing
*/

params [["_what", "", [""]]];

if (!hasInterface) exitWith {};
disableSerialization;
// The shell, not the display: inside the tablet the display is the device,
// which outlives the page (FUNC(uiHost)); the shell goes with the page.
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};
if !(missionNamespace getVariable [QGVAR(uiLive), false]) exitWith {};

TRACE_1("redraw",_what);
[] call FUNC(uiDraw);
