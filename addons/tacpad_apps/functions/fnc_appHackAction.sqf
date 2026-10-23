#include "script_component.hpp"
/*
 * Author: JMSB
 * HACK - ACTION: the selected node and what the suite will do to it.
 *
 *   TARGET    the node and its grid
 *   ACTIONS   DISABLE / SPOOF / TAP, the one the hack will do filled: a
 *             hostile drone is brought down (DISABLE), everything else is
 *             broken into for a product (TAP). On a unit's net - a handset or
 *             a vehicle carrying a set - TAP and SPOOF are a choice
 *             (the suite's canSpoof / tabletSelectAction): SPOOF walks the
 *             net's GPS off true through jmfsb_ew's spoof engine instead of
 *             pulling a product. Dead otherwise, and while a hack runs.
 *   PRODUCT   what to look for (the suite's intelOptions / tabletSelectIntel);
 *             under SPOOF, the EFFECT instead
 *   PROGRESS  the suite's clock, with the time left
 *   YOUR RISK breaking a net is priced by the suite (netFailChance); a set
 *             that transmits can be DF'd once EW listens
 *   NEEDS     the suite's range for the kind
 *   START / ABORT  the suite's tabletAction
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appHack)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appHackAction
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rows = _ctx get "rows";
private _session = _ctx get "session";
private _rowH = _ctx get "rowH";

private _device = _session getOrDefault ["device", objNull];
private _kind = _session getOrDefault ["kind", ""];
private _running = _session getOrDefault ["running", false];
private _progress = _session getOrDefault ["progress", 0];

private _iRow = _rows findIf {(_x select 0) >= 0 && {(_x select 1) isEqualTo _device}};
private _row = if (_iRow < 0) then {[]} else {_rows select _iRow};
private _label = _row param [2, ""];

([_body, _rect, "ACTION", toUpper _label] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _ground = ["ground"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _labelW = (_w - 2 * _pad) * 0.26;
private _valX = _left + _pad + _labelW;
private _valW = _w - 2 * _pad - _labelW;
private _segH = _rowH * 1.1;

private _fnc_label = {
    params ["_ly", "_text"];
    [_body, [_left + _pad, _ly, _labelW, _segH], _text, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
};

private _y = _top + _padY;

if (_row isEqualTo []) exitWith {
    [_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], "Press a node in reach.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

// --------------------------------------------------------------- TARGET ---
[_y, "TARGET"] call _fnc_label;
[_body, [_valX, _y, _valW, _segH], format ["%1 - %2", _label, mapGridPosition _device], _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
_y = _y + _segH + _padY;

// -------------------------------------------------------------- ACTIONS ---
[_y, "ACTIONS"] call _fnc_label;
private _canSpoof = !isNil QEFUNC(hacking,canSpoof) && {[_session] call EFUNC(hacking,canSpoof)};
private _spoofing = _canSpoof && (_session getOrDefault ["action", ""]) isEqualTo "spoof";
private _does = switch (true) do {
    case (_kind isEqualTo "drone"): {"DISABLE"};
    case (_spoofing): {"SPOOF"};
    default {"TAP"};
};
// The segments a press can pick: TAP and SPOOF on a net that can be spoofed.
private _choices = [[], ["TAP", "SPOOF"]] select (_canSpoof && !_running);
private _segW = _valW / (count HACKAPP_ACTIONS);
{
    private _cell = [_valX + _forEachIndex * _segW, _y, _segW - _pad * 0.5, _segH];
    switch (true) do {
        case (_x isEqualTo _does): {
            [_body, _cell, _ink] call EFUNC(tacpad,drawFill);
            [_body, _cell, _x, _ground, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
        };
        case (_x in _choices): {
            [_body, _cell, _x, "line", {
                params ["_ctrl"];
                [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(hacking,tabletSelectAction);
                {["hack"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }, toLower _x] call FUNC(appPageButton);
        };
        default {
            [_body, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
            [_body, _cell, _x, _dim, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
        };
    };
} forEach HACKAPP_ACTIONS;
_y = _y + _segH + _padY;

// -------------------------------------------------------------- PRODUCT ---
private _avail = [[_session] call EFUNC(hacking,intelOptions), []] select _spoofing;
private _intel = _session getOrDefault ["intel", ""];
if (_spoofing) then {
    [_y, "EFFECT"] call _fnc_label;
    [
        _body, [_valX, _y, _valW, _segH],
        format [
            "THEIR GPS WALKS UP TO %1 M OFF TRUE FOR %2 S",
            round (missionNamespace getVariable [QEGVAR(ew,spoofDrift), 0]),
            round (missionNamespace getVariable [QEGVAR(ew,spoofHackTime), 0])
        ],
        _ink, TEXT_LABEL
    ] call EFUNC(tacpad,drawText);
    _y = _y + _segH + _padY;
};
if (_avail isNotEqualTo []) then {
    [_y, "PRODUCT"] call _fnc_label;
    private _pw = _valW / ((count _avail) min HACKAPP_PRODUCT_COLS);
    {
        _x params ["_id", "_text"];
        private _col = _forEachIndex % HACKAPP_PRODUCT_COLS;
        private _lineNo = floor (_forEachIndex / HACKAPP_PRODUCT_COLS);
        [
            _body, [_valX + _col * _pw, _y + _lineNo * (_segH + _padY * 0.5), _pw - _pad * 0.5, _segH], _text,
            ["line", "fill"] select (_id isEqualTo _intel),
            [{
                params ["_ctrl"];
                [_ctrl getVariable [QGVAR(pageData), -1]] call EFUNC(hacking,tabletSelectIntel);
                {["hack"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }, {}] select _running,
            _forEachIndex
        ] call FUNC(appPageButton);
    } forEach _avail;
    _y = _y + (ceil ((count _avail) / HACKAPP_PRODUCT_COLS)) * (_segH + _padY * 0.5) + _padY;
};

// ------------------------------------------------------------- PROGRESS ---
[_y, "PROGRESS"] call _fnc_label;
private _time = _session getOrDefault ["time", 0];
[
    _body, [_valX, _y, _valW, _segH], [QUALITY_UNKNOWN, _progress] select _running,
    if (_running) then {
        format ["%1%2 - %3 LEFT", round (_progress * PERCENT), "%", [_time * (1 - _progress), "MM:SS"] call BIS_fnc_secondsToString]
    } else {"STANDING BY"}
] call FUNC(appPageBar);
_y = _y + _segH;

// ------------------------------------------------------------ YOUR RISK ---
[_y, "YOUR RISK"] call _fnc_label;
if (_kind isEqualTo "unit" && {!isNil QEFUNC(hacking,netFailChance)}) then {
    private _fail = ([] call EFUNC(hacking,netFailChance)) / PERCENT;
    [_body, [_valX, _y, _valW, _segH], _fail, format ["%1%2 NOTICED - THEY MAY DF YOU", round (_fail * PERCENT), "%"], true] call FUNC(appPageBar);
} else {
    [
        _body, [_valX, _y, _valW, _segH],
        ["SEEN IF WATCHED", "NONE ON THE NET"] select (_kind in ["drone", "wreck"]),
        _ink, TEXT_LABEL
    ] call EFUNC(tacpad,drawText);
};
_y = _y + _segH;

// ---------------------------------------------------------------- NEEDS ---
[_y, "NEEDS"] call _fnc_label;
private _needs = format ["STAY WITHIN %1 M", round (_row select 5)];
if ((_row select 6) in ["COOLING", "SPENT"]) then {_needs = format ["%1 - TOWER %2", _needs, _row select 6]};
[_body, [_valX, _y, _valW, _segH], _needs, ([_ink, _muted] select ((_row select 4) <= (_row select 5))), TEXT_LABEL] call EFUNC(tacpad,drawText);
_y = _y + _segH + _padY;

// -------------------------------------------------------- START / ABORT ---
private _btnH = _rowH * 1.3;
private _btnY = (_top + _h - _btnH - _padY) max _y;
private _startW = (_w - 3 * _pad) * 0.75;
[
    _body, [_left + _pad, _btnY, _startW, _btnH], "START", "fill",
    [{
        call EFUNC(hacking,tabletAction);
        [] call FUNC(appHackTrack);
        {["hack"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, {}] select _running
] call FUNC(appPageButton);
[
    _body, [_left + _pad * 2 + _startW, _btnY, _w - 3 * _pad - _startW, _btnH], "ABORT", "alarm",
    [{}, {
        uiNamespace setVariable [QGVAR(hackAbort), true];
        call EFUNC(hacking,tabletAction);
        [] call FUNC(appHackTrack);
        {["hack"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] select _running
] call FUNC(appPageButton);
