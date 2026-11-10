#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//TRAINING's PATIENTS tab: pick the casualty, then put him on a
 * stretcher. A preset (LIGHT .. ARREST, RANDOM) or CUSTOM, which opens one row
 * per body part - the wound kind and how bad, each pressed to step on. Every
 * stretcher is a row: free, or the patient on it and how he is doing (the
 * medic app's own reading when it is loaded). The spawning is the server's
 * (FUNC(patientSpawn), FUNC(patientClear)).
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: Top, relative to the body <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _top] call jmfsb_training_fnc_appPatients
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _y = _top;

// ---- the preset row ----------------------------------------------------------
[_body, [_pad, _y, _w * 0.12, _rowH], "PATIENT", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
private _chipW = (_w * 0.86 - _pad) / count PRESETS;
{
    _x params ["_id", "_label"];
    [_body, [_w * 0.14 + _forEachIndex * _chipW, _y, _chipW - _pad, _rowH], _label, ["line", "fill"] select (_id isEqualTo GVAR(preset)), {
        params ["_ctrl"];
        GVAR(preset) = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), "light"];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _id] call EFUNC(tacpad_apps,appPageButton);
} forEach PRESETS;
_y = _y + _rowH + _padY;

// ---- custom: one row per body part -------------------------------------------
if (GVAR(preset) isEqualTo "custom") then {
    {
        (GVAR(custom) # _forEachIndex) params ["_kind", "_severity"];
        [_body, [_pad, _y, _w * 0.18, _rowH], _x, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
        [_body, [_w * 0.2, _y, _w * 0.2, _rowH], (WOUND_KINDS # _kind) # 1, ["line", "fill"] select (_kind > 0), {
            params ["_ctrl"];
            private _part = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0];
            private _row = GVAR(custom) # _part;
            _row set [0, ((_row # 0) + 1) mod count WOUND_KINDS];
            {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _forEachIndex] call EFUNC(tacpad_apps,appPageButton);
        [_body, [_w * 0.42, _y, _w * 0.2, _rowH], (WOUND_SEVERITY # _severity) # 1, "line", [{}, {
            params ["_ctrl"];
            private _part = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0];
            private _row = GVAR(custom) # _part;
            _row set [1, ((_row # 1) + 1) mod count WOUND_SEVERITY];
            {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] select (_kind > 0), _forEachIndex] call EFUNC(tacpad_apps,appPageButton);
        _y = _y + _rowH + _padY;
    } forEach BODY_LABELS;
};

[_body, [0, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// ---- the stretchers ------------------------------------------------------------
private _stretchers = [] call FUNC(stretchers);
if (_stretchers isEqualTo []) exitWith {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH * 2],
        "NO SPAWN POINTS - PLACE A JMSB - MEDICAL TRAINING MODULE AND NAME ITS POINTS", _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
};

private _footY = _h - _rowH - _padY;
private _canState = !isNil QEFUNC(medic,patientState);
private _listTop = _y;
{
    _x params ["_label", "_stretcher"];
    private _y = _listTop + _forEachIndex * (_rowH + _padY);
    if (_y + _rowH > _footY - _padY) exitWith {};
    private _patient = _stretcher getVariable [QGVAR(patient), objNull];
    private _taken = !isNull _patient;
    private _status = switch (true) do {
        case (!_taken): {"FREE"};
        case (_canState): {MEDIC_STATE_WORDS select (([_patient] call EFUNC(medic,patientState)) # 0)};
        default {"ON THE STRETCHER"};
    };
    [_body, [_pad, _y, _w * 0.2, _rowH], _label, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.22, _y, _w * 0.4, _rowH], _status, [_muted, _accent] select _taken, TEXT_BODY, _taken] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.62, _y, _w * 0.18 - _pad, _rowH], ["PUT PATIENT", "NEW PATIENT"] select _taken, "fill", {
        params ["_ctrl"];
        private _s = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), objNull];
        [QGVAR(patientSpawn), [_s, GVAR(preset), [] call FUNC(customRows), player]] call CBA_fnc_serverEvent;
    }, _stretcher] call EFUNC(tacpad_apps,appPageButton);
    [_body, [_w * 0.8, _y, _w * 0.2 - _pad, _rowH], "REMOVE", "line", [{}, {
        params ["_ctrl"];
        [QGVAR(patientClear), [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), objNull]]] call CBA_fnc_serverEvent;
    }] select _taken, _stretcher] call EFUNC(tacpad_apps,appPageButton);
} forEach _stretchers;

// ---- the foot ------------------------------------------------------------------------
[_body, [_pad, _footY, _w * 0.48 - _pad, _rowH], "RANDOM ON EVERY FREE STRETCHER", "line", {
    {
        _x params ["", "_s"];
        if (isNull (_s getVariable [QGVAR(patient), objNull])) then {
            [QGVAR(patientSpawn), [_s, "random", [], player]] call CBA_fnc_serverEvent;
        };
    } forEach ([] call FUNC(stretchers));
}] call EFUNC(tacpad_apps,appPageButton);
[_body, [_w * 0.52, _footY, _w * 0.48 - _pad, _rowH], "REMOVE EVERY PATIENT", "alarm", {
    [QGVAR(patientClear), [objNull]] call CBA_fnc_serverEvent;
}] call EFUNC(tacpad_apps,appPageButton);
