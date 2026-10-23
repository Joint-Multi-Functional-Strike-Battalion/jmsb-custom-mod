#include "script_component.hpp"
/*
 * Author: JMSB
 * The tab row of a board, with the status note on its right: the picked tab is
 * the ink fill, the rest are outlined. A press stores the tab id in uiNamespace
 * under the given variable and redraws the app next frame - the way every app
 * in the suite reopens itself (see jmfsb_pac_fnc_app).
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: The row's rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: Tabs [[id, label], ...] <ARRAY>
 * 3: The picked tab's id <STRING>
 * 4: uiNamespace variable that holds the picked tab <STRING>
 * 5: App id to redraw <STRING>
 * 6: Status note, right-aligned after the tabs <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [0, 0, _w, _rowH], RADIO_TABS, _tab, QGVAR(radioTab), "radio", "GAME VOICE UNDER IT"] call jmfsb_tacpad_apps_fnc_appPageTabs
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_tabs", [], [[]]],
    ["_picked", "", [""]],
    ["_var", "", [""]],
    ["_app", "", [""]],
    ["_note", "", [""]]
];

if (isNull _body || {_tabs isEqualTo []}) exitWith {};

_rect params ["_left", "_top", "_w", "_h"];

private _ground = ["ground"] call EFUNC(tacpad,theme);
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
// The tabs take the left half; the note has the rest.
private _tabW = (_w * 0.5) / (count _tabs);

{
    _x params ["_id", "_label"];
    private _tx = _left + _forEachIndex * _tabW;
    private _cell = [_tx, _top, _tabW - _pad, _h];
    private _on = _id isEqualTo _picked;

    if (_on) then {
        [_body, _cell, _ink] call EFUNC(tacpad,drawFill);
    } else {
        [_body, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    };
    [_body, _cell, _label, ([_muted, _ground] select _on), TEXT_BODY, true, "center", true] call EFUNC(tacpad,drawText);

    private _hit = [_body, _cell, {
        params ["_ctrl"];
        uiNamespace setVariable [_ctrl getVariable [QGVAR(pageVar), ""], _ctrl getVariable [QGVAR(pageTab), ""]];
        private _app = _ctrl getVariable [QGVAR(pageApp), ""];
        [{[_this] call EFUNC(tacpad,openApp)}, _app] call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pageVar), _var];
    _hit setVariable [QGVAR(pageTab), _id];
    _hit setVariable [QGVAR(pageApp), _app];
} forEach _tabs;

if (_note isNotEqualTo "") then {
    [_body, [_left + _w * 0.5, _top, _w * 0.5 - _pad, _h], _note, _muted, TEXT_LABEL, false, "right"] call EFUNC(tacpad,drawText);
};
