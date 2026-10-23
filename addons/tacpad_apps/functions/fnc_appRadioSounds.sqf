#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO - NETS, the right column: SOUNDS over KEYS (docs/DESIGN_VOICE.md,
 * "Sounds" and "Numpad").
 *
 * SOUNDS are the voice addon's own CBA settings (RADIO_SOUNDS), changed through
 * FUNC(setSetting) / FUNC(settingStep) so a change persists as Addon Options
 * keeps it and a forced one is drawn read-only. A setting the voice addon does
 * not declare reads NOT BUILT.
 *
 * KEYS is read off the player's own CBA bindings, so a key he has rebound reads
 * as rebound - then the walking view's F-keys, which are the device buttons'
 * default actions.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Column rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioSounds
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

_rect params ["_x0", "_y0", "_w0", "_h0"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _soundsH = (_h0 - _padY) * PAGE_SPLIT_RIGHT;

// ------------------------------------------------------------- SOUNDS ----
([_body, [_x0, _y0, _w0, _soundsH], "SOUNDS", "BEEPS AND STATIC"] call FUNC(appPagePanel)) params ["_left", "_top", "_w"];
private _labelW = _w * 0.42;
private _ctlX = _left + _pad + _labelW;
private _ctlW = _w - _labelW - 2 * _pad;
private _step = _rowH * 1.5;

{
    _x params ["_label", "_setting", "_kind"];
    private _ry = _top + _padY + _forEachIndex * _step;
    [_body, [_left + _pad, _ry, _labelW, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);

    if (isNil _setting) then {
        [_body, [_ctlX, _ry, _ctlW, _rowH], "NOT BUILT", _dim, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
        continue;
    };

    private _now = missionNamespace getVariable [_setting, false];
    private _locked = [_setting] call FUNC(settingLocked);

    if (_kind isEqualTo "slider") then {
        if !(_now isEqualType 0) then {_now = 0};
        [_body, [_ctlX, _ry, _ctlW * 0.6, _rowH], _now / RADIO_BEEP_MAX, format ["%1%2", round (_now * PERCENT), "%"]] call FUNC(appPageBar);
        {
            _x params ["_glyph", "_delta", "_at"];
            [_body, [_ctlX + _ctlW * _at, _ry, _ctlW * 0.18, _rowH], _glyph, "line", [{
                params ["_ctrl"];
                (_ctrl getVariable [QGVAR(pageData), []]) params ["_name", "_by"];
                [_name, _by, 0, RADIO_BEEP_MAX, RADIO_BEEP_DECIMALS, false] call FUNC(settingStep);
                {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }, {}] select _locked, [_setting, _delta]] call FUNC(appPageButton);
        } forEach [["-", -RADIO_BEEP_STEP, 0.62], ["+", RADIO_BEEP_STEP, 0.81]];
        continue;
    };

    if !(_now isEqualType true) then {_now = false};
    private _segW = _ctlW * 0.5;
    {
        _x params ["_word", "_value"];
        [_body, [_ctlX + _forEachIndex * _segW, _ry, _segW - _pad * 0.5, _rowH], _word, ["line", "fill"] select (_now isEqualTo _value), [{
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(pageData), []]) params ["_name", "_set"];
            [_name, _set, false] call FUNC(setSetting);
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, {}] select _locked, [_setting, _value]] call FUNC(appPageButton);
    } forEach [["OFF", false], [["ON", "BY QUALITY"] select (_label isEqualTo "STATIC BY QUALITY"), true]];
} forEach RADIO_SOUNDS;

[
    _body, [_left + _pad, _top + _padY + (count RADIO_SOUNDS) * _step, _w - 2 * _pad, _rowH],
    "TEAM mid tone - C2 low - A2G high - CALL two-tone", _muted, TEXT_LABEL
] call EFUNC(tacpad,drawText);

// --------------------------------------------------------------- KEYS ----
private _keysY = _y0 + _soundsH + _padY;
([_body, [_x0, _keysY, _w0, _h0 - _soundsH - _padY], "KEYS", "YOUR BINDINGS"] call FUNC(appPagePanel)) params ["_kl", "_kt", "_kw"];

// One key, as the player has it bound: modifiers, then the key's own name.
private _fnc_bound = {
    params ["_action"];
    private _bind = [JMFSB_CATEGORY, _action] call CBA_fnc_getKeybind;
    if (isNil "_bind") exitWith {"--"};
    (_bind param [5, [0, []]]) params [["_dik", 0, [0]], ["_mods", [], [[]]]];
    if (_dik <= 1) exitWith {"UNBOUND"};
    private _words = [];
    {
        if (_mods param [_forEachIndex, false]) then {_words pushBack _x};
    } forEach ["SHIFT", "CTRL", "ALT"];
    _words pushBack (((keyName _dik) splitString """") joinString "");
    _words joinString "+"
};

private _keyW = _kw * 0.4;
{
    _x params ["_does", "_actions"];
    private _ry = _kt + _forEachIndex * _rowH * 1.2;
    [_body, [_kl + _pad, _ry, _keyW - _pad, _rowH], (_actions apply {[_x] call _fnc_bound}) joinString " ", _ink, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    [_body, [_kl + _keyW, _ry, _kw - _keyW - _pad, _rowH], _does, _ink, TEXT_LABEL] call EFUNC(tacpad,drawText);
    [_body, [_kl, _ry + _rowH * 1.2 - RULE_THIN * pixelH, _kw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach RADIO_KEY_ROWS;

private _walkY = _kt + (count RADIO_KEY_ROWS) * _rowH * 1.2 + _padY;
[_body, [_kl + _pad, _walkY, _kw - 2 * _pad, _rowH], "ON THE WALKING VIEW", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
{
    _x params ["_key", "_does"];
    private _ry = _walkY + (_forEachIndex + 1) * _rowH;
    [_body, [_kl + _pad, _ry, _keyW - _pad, _rowH], _key, _ink, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    [_body, [_kl + _keyW, _ry, _kw - _keyW - _pad, _rowH], _does, _ink, TEXT_LABEL] call EFUNC(tacpad,drawText);
} forEach RADIO_WALK_KEYS;
