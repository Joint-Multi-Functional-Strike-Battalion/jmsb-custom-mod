#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW app's EP tab (DESIGN_EW "EP"): his own sets, one row each - the
 * profile, how far it is heard (FUNC(exposure)) and EMCON 0-3. A press sets
 * the level in RF (jmfsb_rf_fnc_setState "emcon") and asks the server for a
 * fresh slice. EMCON is read by EW for exposure and intercept (power cap,
 * beacon duty, SILENT not heard); RF itself stops relaying from MINIMISE.
 * Under the sets, what each level costs, and the last DF ON YOU.
 *
 * Arguments:
 * 0: App body <CONTROL>
 * 1: Top y <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, 0.05] call jmfsb_ew_fnc_appEp
 *
 * Public: No
 */

#define EMCON_LIMITS ["NO LIMIT", "2 W, BFT 10 S", "BURST DATA, NO RELAY, BFT 30 S", "RECEIVE ONLY"]

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _w = (ctrlPosition _body) select 2;
private _pad = PAD * HOST_W;

GVAR(mine) params ["", "", "_nodes", "", "", "", "", "_threats"];

if (_nodes isEqualTo []) exitWith {
    [_body, [_pad, _top, _w - 2 * _pad, _rowH], "NO SET - NOTHING OF YOURS IS ON THE AIR", _muted, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
};

private _levels = EMCON_LEVELS;
private _btnX = _w * 0.42;
private _btnW = (_w - _btnX - _pad) / count _levels;
{
    _x params ["_id", "_profile", "_emcon", "_exposure", "_nets"];
    [_body, [_pad, _top, _w * 0.2, _rowH], toUpper _profile, _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.2, _top, _w * 0.22, _rowH], format ["HEARD %1 KM", (_exposure / 1000) toFixed 1], [_ink, _accentText] select (_exposure > 0 && _emcon == 0), TEXT_BODY] call EFUNC(tacpad,drawText);
    {
        [_body, [_btnX + _forEachIndex * _btnW, _top, _btnW - _pad, _rowH], _x, _forEachIndex isEqualTo _emcon, {
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(data), ["", 0]]) params ["_node", "_level"];
            [_node, [["emcon", _level]]] call EFUNC(rf,setState);
            [QGVAR(refresh), [player]] call CBA_fnc_serverEvent;
        }, [_id, _forEachIndex]] call FUNC(appButton);
    } forEach _levels;
    _top = _top + _rowH;
    [_body, [_pad, _top, _w - 2 * _pad, _rowH], (_nets joinString " / "), _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
    _top = _top + _rowH * 1.2;
} forEach _nodes;

[_body, [0, _top, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_top = _top + _rowH * 0.3;
{
    [_body, [_pad, _top, _w * 0.3, _rowH], format ["%1 %2", _forEachIndex, _x], _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.3, _top, _w * 0.7 - _pad, _rowH], EMCON_LIMITS select _forEachIndex, _ink, TEXT_BODY] call EFUNC(tacpad,drawText);
    _top = _top + _rowH * 0.9;
} forEach _levels;

private _df = _threats select {(_x select 1) isEqualTo THREAT_DF};
_top = _top + _rowH * 0.4;
private _last = if (_df isEqualTo []) then {"NO DF CUT ON YOU HEARD OF"} else {
    format ["LAST DF ON YOU %1 S AGO - MOVE AFTER YOU TRANSMIT", round (CBA_missionTime - ((_df select -1) select 0))]
};
[_body, [_pad, _top, _w - 2 * _pad, _rowH], _last, [_muted, _accentText] select (_df isNotEqualTo []), TEXT_BODY, _df isNotEqualTo []] call EFUNC(tacpad,drawText);
