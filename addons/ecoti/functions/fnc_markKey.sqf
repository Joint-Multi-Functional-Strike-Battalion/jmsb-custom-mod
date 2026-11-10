#include "script_component.hpp"
/*
 * Author: YonV
 * The player's mark key (user, 2026-11-06: "the color when the keybind is
 * pressed need a 6-9 question on color"): the building under his crosshair
 * (FUNC(markTarget)), then the colour asked on the walking view's strip -
 * numpad 6-9 pick, numpad 0 / . page (jmfsb_tacpad_fnc_askChoice) - with CLEAR
 * on the last page when the building is already marked. The pick is sent to
 * the server (FUNC(markPick)).
 *
 * WITHOUT A PHONE OR SIDE DEVICE UP there is no strip to ask on: each press
 * steps the building to the next colour, past the last to no mark.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_markKey
 *
 * Public: No
 */

private _building = [] call FUNC(markTarget);
if (isNull _building) exitWith {
    hintSilent "MARK - NO BUILDING UNDER THE CROSSHAIR";
    true
};

private _marks = missionNamespace getVariable [QGVAR(marks), []];
private _at = _marks findIf {(_x select 0) isEqualTo _building};
private _name = toUpper getText (configOf _building >> "displayName");
if (_name isEqualTo "") then {_name = MARK_DEFAULT_LABEL};

private _strip = !isNil QEFUNC(tacpad,askChoice)
    && {!isNull (uiNamespace getVariable [QEGVAR(devices,overlayDisplay), displayNull])};

if (!_strip) exitWith {
    private _next = if (_at < 0) then {0} else {((_marks select _at) select 1) + 1};
    if (_next >= count MARK_COLOURS) then {_next = MARK_CLEAR};
    [0 max _next, [MARK_CLEAR_WORD, (MARK_COLOURS select (0 max _next)) select 0] select (_next >= 0), [_building, _next]] call FUNC(markPick);
    true
};

private _words = (MARK_COLOURS apply {_x select 0}) + ([[], [MARK_CLEAR_WORD]] select (_at >= 0));
[MARK_ASK_ID, format [MARK_ASK_TEXT, _name], _words, {
    params ["_index", "_word", "_args"];
    [_index, _word, _args] call FUNC(markPick);
}, [_building], MARK_ASK_S] call EFUNC(tacpad,askChoice);

true
