#include "script_component.hpp"
/*
 * Author: YonV
 * The SQUAD app's MEMBER page (DESIGN_TABLET_APPS.md: "MEMBER: wounds, blood,
 * ammo, radio, distance. Buttons: SHOW ON MAP, CALL"), drawn down the app's
 * right rail in place of STRENGTH while a man is selected. BACK clears the
 * selection and the rail is STRENGTH again.
 *
 * EVERY LINE IS SOMEBODY ELSE'S READ, so the page cannot disagree with the
 * screen that owns it:
 * - WOUNDS and BLOOD are the MEDIC app's (jmfsb_medic_fnc_patientState,
 *   readBody, readStatus) - the open wounds per part, tourniquets, and the
 *   blood volume line. Without jmfsb_medic or ACE medical they say so.
 * - AMMO is FUNC(ammoState), the number the STRENGTH tile averages.
 * - RADIO is the man's own published active net (FUNC(radioPublish)), the
 *   roster's RADIO column.
 * - LINK is FUNC(squadLink), his reach on DATA - what a CALL needs.
 * - SHOW ON MAP is the MEDIC app's (jmfsb_medic_fnc_showOnMap): closes the app
 *   and pans the host's map to him, with the BFT member marks hung on a device
 *   map. CALL rings him through FUNC(radioDial), as the RADIO app does.
 *
 * MEDIC TO HIM is not here: nothing in the mod sends a medic to a man (the
 * CASEVAC card is an air lift, and a message cannot be opened pre-tagged
 * MEDICS). See README.
 *
 * Arguments:
 * 0: Parent to draw into <CONTROL>
 * 1: Area [x, y, w, h] <ARRAY>
 * 2: The man <OBJECT>
 * 3: His STATUS, as the roster words it <STRING>
 * 4: Status is trouble - drawn in the accent <BOOL>
 * 5: Down or dead - the mark is drawn faded <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [_rx, 0, _rw, _h], _unit, "Effective", false, false] call jmfsb_tacpad_apps_fnc_appSquadMember
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_unit", objNull, [objNull]],
    ["_status", "", [""]],
    ["_statusHot", false, [false]],
    ["_faded", false, [false]]
];

if (isNull _parent || {isNull _unit}) exitWith {};

_rect params ["_left", "_top", "_w"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _self = _unit isEqualTo player;

// ------------------------------------------------------------- the head ----
private _y = _top;
[_parent, [_left, _y, _w * 0.6, _rowH], "MEMBER", _muted, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
private _backW = _w * 0.36;
[_parent, [_left + _w - _backW, _y, _backW, _rowH], "< BACK", "line", {
    GVAR(squadSelected) = objNull;
    {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call FUNC(appPageButton);
_y = _y + _rowH + _padY;
[_parent, [_left, _y, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + RULE_THICK * pixelH + _padY;

// The man: his BFT mark and name, then his role and fire team under them.
private _markW = [_parent, [_left, _y, _btnH], _unit, _faded] call FUNC(squadIcon);
[
    _parent, [_left + _markW + _pad, _y, _w - _markW - _pad, _btnH],
    format ["%1 %2", [rank _unit] call EFUNC(tacpad,rankShort), toUpper name _unit], _ink, TEXT_TITLE, true
] call EFUNC(tacpad,drawText);
_y = _y + _btnH;
private _team = assignedTeam _unit;
[
    _parent, [_left, _y, _w, _rowH],
    format ["%1 - %2 TEAM", [_unit] call EFUNC(tacpad,roleShort), [_team, "MAIN"] select (_team isEqualTo "")],
    _muted, TEXT_LABEL, true, "left", true
] call EFUNC(tacpad,drawText);
_y = _y + _rowH + _padY;

// ------------------------------------------------------------ the lines ----
// The MEDIC app's reads, when it and ACE medical are both there.
private _wounds = "NO ACE MEDICAL";
private _woundsHot = false;
private _blood = "--";
private _bloodHot = false;
if (!isNil QEFUNC(medic,readBody) && {missionNamespace getVariable [QEGVAR(medic,ace), false]}) then {
    ([_unit] call EFUNC(medic,patientState)) params ["", "", "_grade"];

    // [label, open, bandaged, bleeding, tourniquet, ...] per part, head down.
    private _parts = [_unit] call EFUNC(medic,readBody);
    private _open = _parts select {(_x # 1) > 0};
    private _words = (_open select [0, SQUAD_WOUND_PARTS]) apply {format ["%1 %2", _x # 0, _x # 1]};
    if (count _open > SQUAD_WOUND_PARTS) then {
        _words pushBack format ["+%1", count _open - SQUAD_WOUND_PARTS];
    };
    private _tq = {_x # 4} count _parts;
    if (_tq > 0) then {_words pushBack format ["TQ %1", _tq]};
    _wounds = [_words joinString " - ", "NONE OPEN"] select (_words isEqualTo []);
    _woundsHot = (_parts findIf {_x # 3}) > -1;

    // The patient page's BLOOD VOLUME line, "5.2 L", as a share of a full man.
    private _lines = [_unit, _grade] call EFUNC(medic,readStatus);
    private _i = _lines findIf {(_x # 0) isEqualTo "BLOOD VOLUME"};
    if (_i > -1) then {
        (_lines # _i) params ["", "_volume", "", "_hot"];
        _blood = format ["%1%2 - %3", round (parseNumber _volume / SQUAD_BLOOD_FULL * PERCENT), "%", _volume];
        _bloodHot = _hot;
    };
};

([_unit] call FUNC(ammoState)) params ["_ammoPct", "_rounds"];
private _radio = _unit getVariable [QGVAR(radio), ""];

private _quality = [_unit] call FUNC(squadLink);
private _link = switch (true) do {
    case (_quality < 0): {"-"};
    case (_quality isEqualTo 0): {"NO ROUTE ON DATA"};
    default {format ["%1%2 ON DATA", round (_quality * PERCENT), "%"]};
};

private _dist = if (_self) then {"YOU"} else {
    format [
        "%1 M - BRG %2",
        round (player distance _unit),
        [(round (player getDir _unit)) mod SQUAD_BEARING_FULL, SQUAD_BEARING_DIGITS] call CBA_fnc_formatNumber
    ]
};

_y = _y + ([_parent, [_left, _y, _w], [
    ["STATE", toUpper _status, _statusHot],
    ["WOUNDS", _wounds, _woundsHot],
    ["BLOOD", _blood, _bloodHot],
    ["AMMO", [format ["%1%2 - %3 RDS", _ammoPct, "%", _rounds], "NO PRIMARY"] select (_ammoPct < 0), _ammoPct >= 0 && _ammoPct < SQUAD_AMMO_LOW],
    ["RADIO", [_radio, "NO SET"] select (_radio isEqualTo ""), false],
    ["LINK", _link, _quality isEqualTo 0],
    ["DIST", _dist, false]
], 1] call FUNC(kvRow));
_y = _y + _padY * 2;

// ---------------------------------------------------------- the buttons ----
// A button whose service is not loaded - or a CALL to an AI, a dead man or
// yourself - is drawn dead rather than left to do nothing.
private _canMap = !isNil QEFUNC(medic,showOnMap);
[_parent, [_left, _y, _w, _btnH], "SHOW ON MAP", "fill", [{}, {
    params ["_ctrl"];
    [_ctrl getVariable [QGVAR(pageData), objNull]] call EFUNC(medic,showOnMap);
}] select _canMap, _unit] call FUNC(appPageButton);
_y = _y + _btnH + _padY;

private _canCall = !_self && {!isNil QEFUNC(voice,call)} && {alive _unit} && {isPlayer _unit};
[_parent, [_left, _y, _w, _btnH], "CALL", "line", [{}, {
    params ["_ctrl"];
    private _to = _ctrl getVariable [QGVAR(pageData), objNull];
    if (isNull _to) exitWith {};
    [[_to]] call FUNC(radioDial);
    {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] select _canCall, _unit] call FUNC(appPageButton);
