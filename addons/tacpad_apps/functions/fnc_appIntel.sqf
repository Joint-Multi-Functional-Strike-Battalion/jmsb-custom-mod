#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//INTEL - what the unit has taken off hacked terminals. Folders down the
 * left, the open file down the right.
 *
 * IT IS A UNIT'S FILING CABINET, NOT A PLAYER'S. FUNC(productPackage) files a
 * recovered entry against the SIDE, so a man who was nowhere near the terminal
 * reads what the section brought back, and a man who hacked it and then died
 * has not taken the intelligence with him. That is the whole reason intel is
 * worth recovering rather than worth seeing.
 *
 * THE CONTENT IS THE MISSION'S. Titles, text and pictures come from
 * Jmfsb_IntelPackages in the mission config, put on a device by a JMSB - Intel
 * Package module. This app knows how to show a file and nothing whatever about
 * what is in one.
 *
 * A PACKAGE ARRIVES IN PIECES, and the folder says so: a hack yields a share,
 * so a folder can hold two files today and five after the next visit. Nothing
 * here says how many are still on the terminal - that would be the mission
 * telling the player how much more to steal, which is the terminal's business
 * and not the reader's.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "INTEL", 0.62, 0.58] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _h = _pos # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

// EVERYTHING THIS SIDE HOLDS. Broadcast by the server as it is recovered - see
// EFUNC(hacking,productPackage) - so this is a read, never a request.
private _store = missionNamespace getVariable [QEGVAR(hacking,packageIntel), createHashMap];
// `player`, as in FUNC(tileData): ACE is optional, and without it ACE_player
// is nil and the whole screen throws on this line.
private _held = _store getOrDefault [str (side group player), []];

// Grouped into folders in the order they were first recovered, which is the
// order the unit learned things in and the only order that means anything.
private _folders = [];
private _byFolder = createHashMap;
{
    _x params ["_pkg", "_label"];
    if !(_pkg in _folders) then {
        _folders pushBack _pkg;
        _byFolder set [_pkg, [_label, []]];
    };
    ((_byFolder get _pkg) # 1) pushBack _x;
} forEach _held;

private _openPkg = GVAR(intelFolder);
if !(_openPkg in _folders) then { _openPkg = _folders param [0, ""] };
private _openEntry = GVAR(intelEntry);

private _listW = _w * 0.38;
[_body, [_listW, 0, RULE_THICK * pixelW, _h], _ink] call EFUNC(tacpad,drawFill);

// -------------------------------------------------------------- the folders --
[_body, [_pad, 0, _listW - 2 * _pad, _rowH], "RECOVERED", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_pad, _rowH, _listW - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

if (_folders isEqualTo []) then {
    [_body, [_pad, _rowH * 1.4, _listW - 2 * _pad, _rowH], "NOTHING RECOVERED", _dim, TEXT_TITLE, false] call EFUNC(tacpad,drawText);
    [_body, [_pad, _rowH * 2.4, _listW - 2 * _pad, _rowH * 3], "Break into a terminal carrying files and what comes off it is filed here.", _dim, TEXT_BODY, false] call EFUNC(tacpad,drawText);
};

// every row below - folder or file - steps down onto itself before it draws
private _y = _rowH * 1.3 - _rowH;

{
    _y = _y + _rowH;
    private _pkg = _x;
    (_byFolder get _pkg) params ["_label", "_entries"];
    private _on = _pkg isEqualTo _openPkg;

    if (_on) then {
        [_body, [_pad, _y, _listW - 2 * _pad, _rowH], [ARR_4(_accent # 0,_accent # 1,_accent # 2,0.14)]] call EFUNC(tacpad,drawFill);
    };

    [_body, [_pad * 2, _y, _listW * 0.72, _rowH], _label, ([_ink, _mute] select (!_on)), TEXT_TITLE, _on] call EFUNC(tacpad,drawText);
    [_body, [_listW * 0.72, _y, _listW * 0.28 - _pad * 2, _rowH], str count _entries, _mute, TEXT_BODY, false, "right"] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_pad, _y, _listW - 2 * _pad, _rowH], {
        params ["_ctrl"];
        GVAR(intelFolder) = _ctrl getVariable [ARR_2(QGVAR(pkg),"")];
        GVAR(intelEntry) = "";
        {["intel"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pkg), _pkg];

    // The files inside the open folder, indented under it. A closed folder is
    // one row - forty recovered files should not be forty rows the moment the
    // app opens.
    if (_on) then {
        {
            _y = _y + _rowH;
            _x params ["", "", "_id", "_title"];
            private _sel = _id isEqualTo _openEntry;
            private _text = ["- ", "> "] select _sel;

            [_body, [_pad * 4, _y, _listW - _pad * 5, _rowH], _text + (["UNTITLED", _title] select (_title isNotEqualTo "")), ([_mute, _ink] select _sel), TEXT_BODY, _sel] call EFUNC(tacpad,drawText);

            private _eh = [_body, [_pad * 3, _y, _listW - _pad * 4, _rowH], {
                params ["_ctrl"];
                GVAR(intelEntry) = _ctrl getVariable [ARR_2(QGVAR(entry),"")];
                {["intel"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }] call EFUNC(tacpad,drawHit);
            _eh setVariable [QGVAR(entry), _id];
        } forEach _entries;
    };
} forEach _folders;

// ----------------------------------------------------------------- the file --
private _rx = _listW + RULE_THICK * pixelW + _pad * 2;
private _rw = _w - _rx - _pad * 2;
private _ry = 0;

private _open = [];
{
    if ((_x # 2) isEqualTo _openEntry) then { _open = _x };
} forEach (_byFolder getOrDefault [_openPkg, ["", []]] # 1);

// Nothing picked yet: the first file of the open folder, so a player who has
// just recovered something is reading it rather than looking at a prompt.
if (_open isEqualTo []) then {
    _open = (_byFolder getOrDefault [_openPkg, ["", []]] # 1) param [0, []];
};

if (_open isEqualTo []) exitWith {};

_open params ["", "_folderLabel", "", "_title", "_text", "_image"];

[_body, [_rx, _ry, _rw, _rowH], _folderLabel, _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH;

[_body, [_rx, _ry, _rw, _rowH], (["UNTITLED", _title] select (_title isNotEqualTo "")), _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH + _padY;
[_body, [_rx, _ry, _rw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_ry = _ry + _padY * 2;

// THE PICTURE FIRST, because a photograph is read before its caption and
// because an entry that has one usually IS the photograph. Half the remaining
// height, so the text under it always has somewhere to go.
//
// NOT EFUNC(tacpad,drawIcon), WHICH IS SQUARE BY CONSTRUCTION - it derives its
// width from its height, which is right for a status pip and wrong for a
// reconnaissance photograph. RscPictureKeepAspect fits the frame and keeps the
// shape it was drawn in.
if (_image isNotEqualTo "") then {
    private _picH = (_h - _ry) * 0.5;
    private _pic = _display ctrlCreate ["RscPictureKeepAspect", -1, _body];
    _pic ctrlSetPosition [_rx, _ry, _rw, _picH];
    _pic ctrlSetText _image;
    _pic ctrlCommit 0;
    _ry = _ry + _picH + _padY * 2;
};

if (_text isNotEqualTo "") then {
    [_body, [_rx, _ry, _rw, _h - _ry], _text, _ink, TEXT_TITLE, false, "left"] call EFUNC(tacpad,drawText);
};

nil
