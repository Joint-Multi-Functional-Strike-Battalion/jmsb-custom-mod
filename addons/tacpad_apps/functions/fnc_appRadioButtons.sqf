#include "script_component.hpp"
/*
 * Author: YonV
 * RADIO - NETS, the right column's BUTTONS (user, 2026-11-07: "a player
 * should be able in the radio app to set which buttons are what, so 4 quick
 * access and then 2 pages of 4 additional"): the twelve net buttons of the
 * device net rows - QUICK 1-4, then pages 2 and 3 - each with what it is set
 * to and the net on it now.
 *
 * THE SETTING IS A DROP-DOWN (user, 2026-11-08): AUTO, then each net he is on
 * in the voice API's order. Not DIRECT (no chip) and not a call's net (it
 * lasts one call). One net may be set on several buttons - on more than one
 * page. A net set on a button he is not on now reads "(NOT ON IT)" and
 * leaves that button empty on the rows. The setting is jmfsb_devices'
 * (jmfsb_devices_fnc_netAssign, kept in his profile); what is on each button
 * now is its jmfsb_devices_fnc_netButtons - AUTO buttons filled in order,
 * quick first.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioButtons
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);

([_body, _rect, "NET BUTTONS", "QUICK 1-4, PAGES 2 AND 3"] call FUNC(appPagePanel)) params ["_left", "_top", "_w"];

if (isNil QEFUNC(devices,netAssign)) exitWith {
    [_body, [_left + _pad, _top, _w - 2 * _pad, _rowH], "The net buttons are the JMSB devices addon's, which this mission does not load.", _muted, TEXT_BODY] call EFUNC(tacpad,drawText);
};

private _assigned = missionNamespace getVariable [QEGVAR(devices,netButtons), []];
private _nets = (_ctx get "netState") select {!((_x param [2, ""]) in [VOICE_KIND_DIRECT, VOICE_KIND_CALL])};
private _names = createHashMapFromArray (_nets apply {[_x param [0, ""], toUpper (_x param [1, ""])]});
private _fontH = [TEXT_BODY] call EFUNC(tacpad,textH);
private _now = ([] call EFUNC(devices,netButtons)) param [0, []];

private _labelW = _w * RADIO_BUTTON_LABEL_K;
private _setW = _w * RADIO_BUTTON_SET_K;
private _step = _rowH * RADIO_BUTTON_STEP;
{
    private _netId = _x;
    private _ry = _top + _forEachIndex * _step;
    private _label = format ["%1 %2 %3", RADIO_NET_PAGE_NAMES param [floor (_forEachIndex / RADIO_NET_PAGE_SIZE), ""], MIDDOT_TEXT, (_forEachIndex mod RADIO_NET_PAGE_SIZE) + 1];
    [_body, [_left + _pad, _ry, _labelW - _pad, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);

    // the setting: a drop-down of AUTO and the nets he is on
    private _combo = (ctrlParent _body) ctrlCreate ["RscCombo", -1, _body];
    _combo ctrlSetPosition [_left + _labelW, _ry, _setW - _pad, _rowH];
    _combo ctrlSetFontHeight _fontH;
    _combo ctrlCommit 0;
    _combo lbSetData [_combo lbAdd RADIO_BUTTON_AUTO, ""];
    {
        private _id = _x param [0, ""];
        _combo lbSetData [_combo lbAdd (_names get _id), _id];
    } forEach _nets;
    if (_netId isNotEqualTo "" && {!(_netId in _names)}) then {
        _combo lbSetData [_combo lbAdd format [RADIO_BUTTON_ABSENT, toUpper _netId], _netId];
    };
    private _sel = 0;
    for "_i" from 0 to (lbSize _combo - 1) do {
        if ((_combo lbData _i) isEqualTo _netId) exitWith {_sel = _i};
    };
    _combo lbSetCurSel _sel;
    _combo setVariable [QGVAR(pageData), _forEachIndex];
    _combo ctrlAddEventHandler ["LBSelChanged", {
        params ["_ctrl", "_index"];
        private _button = _ctrl getVariable [QGVAR(pageData), -1];
        [_button, _ctrl lbData _index] call EFUNC(devices,netAssign);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }];

    private _on = (_now param [_forEachIndex, []]) param [1, ""];
    [_body, [_left + _labelW + _setW, _ry, _w - _labelW - _setW - _pad, _rowH], [_on, "-"] select (_on isEqualTo ""), _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_left, _ry + _step - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _assigned;
