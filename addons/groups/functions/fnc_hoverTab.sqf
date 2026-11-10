#include "script_component.hpp"
/*
    Author: YonV

    Description:
        Lifts one platoon tab under the pointer, and puts it back when the
        pointer leaves.

        WHY THIS IS NOT THE BUTTON'S OWN colorBackgroundActive. A tab is two
        controls - a structured text label with a transparent button on top of
        it to catch the click (see script_component.hpp) - and the button is
        the one on top. Any fill it painted on hover would paint over the two
        lines of text under it, so the button stays transparent in every state
        and hands the pointer to this instead, which lifts the LABEL.

        THE COLOURS ARE MIXED ONCE, by FUNC(selectPlatoon), and left in
        GVAR(tabLift) / GVAR(tabHover). This runs on every pointer move across
        the row; mixing a theme each time would be work for nothing.

        A TAB THE MISSION DID NOT DECLARE IS HIDDEN, not absent - the row is
        always MAX_PLT_TABS controls - so the index is checked against the tab
        list rather than against the row.

    Parameters:
        0: NUMBER - which tab, zero-based
        1: BOOL   - true entering, false leaving

    Returns:
        NOTHING
*/

disableSerialization;

params [["_index", 0, [0]], ["_on", false, [false]]];

private _display = findDisplay 9702;
if (isNull _display) exitWith {};

private _tabs = missionNamespace getVariable [QGVAR(platoonTabs), []];
if (_index < 0 || {_index >= count _tabs}) exitWith {};

private _ctrl = _display displayCtrl (IDC_PLT_TAB + _index);
if (isNull _ctrl) exitWith {};

// Defaults rather than an exit: the row is drawn before a pointer can reach it,
// so these are always set - and if a future path ever gets here first, a tab
// that does not light up beats a tab that throws.
private _lift = missionNamespace getVariable [QGVAR(tabLift), [0.14, 0.14, 0.14, 1]];
private _hover = missionNamespace getVariable [QGVAR(tabHover), [0.20, 0.20, 0.20, 1]];

_ctrl ctrlSetBackgroundColor ([_lift, _hover] select _on);
