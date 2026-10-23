#include "script_component.hpp"
/*
 * Author: JMSB
 * The reader's left rail (handoff 1a, pane 1): the brand block, the nets with
 * their unread counts, the ON NET roster and the self block pinned to the foot.
 *
 * A RESTYLE OF WHAT WAS IN FUNC(readerDraw), NOT A NEW RAIL. Which nets a man
 * may see is still EFUNC(messaging,railNets)'s answer, a net press still
 * retargets an open message, and the roster still folds per squad - only the
 * look moved to the design: the rail on the surface tone, the selected net a
 * solid accent row, the roster's online state a 7 px square.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: Rail width <NUMBER>
 * 2: Rail height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_root, _railW, _h] call jmfsb_tacpad_fnc_readerRail
 *
 * Public: No
 */

params [["_root", controlNull, [controlNull]], ["_railW", 0, [0]], ["_h", 0, [0]]];

if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _surface = ["surface"] call FUNC(theme);
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _side = READER_INSET * _pad;
private _innerW = _railW - 2 * _side;
private _ruleH = RULE_THICK * pixelH;

[_root, [0, 0, _railW, _h], _surface] call FUNC(drawFill);

// ----------------------------------------------------------------- brand ---
private _rowY = READER_INSET * _padY;
[_root, [_side, _rowY, _innerW, _rowH * 1.2], "TAC//MSG", _ink, READER_BRAND_SIZE, true] call FUNC(drawText);
_rowY = _rowY + _rowH * 1.3;
[
    _root, [_side, _rowY, _innerW, _rowH * 0.8],
    format ["%1 - %2", groupId (group player), briefingName],
    _muted, READER_K_SIZE, true, "left", true
] call FUNC(drawText);
_rowY = _rowY + _rowH + _padY;

[_root, [0, _rowY, _railW, _ruleH], _dim] call FUNC(drawFill);
_rowY = _rowY + _ruleH + READER_INSET * _padY;

// ------------------------------------------------------------------ nets ---
[_root, [_side, _rowY, _innerW, _rowH * 0.8], "NETS", _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
_rowY = _rowY + _rowH;

private _index = EGVAR(messaging,index);

// Kept for the legacy SQUAD key, which older state may still hold.
private _squadBox = format ["G:%1", groupId (group player)];

// WHAT THIS MAN MAY SEE, AND NOTHING ELSE - EFUNC(messaging,railNets) is the
// role gate, shared with the compose target list. A box the index knows about
// that nothing declared still gets a row; the server only indexes what it
// would deliver, so that cannot leak another squad's net back in.
private _nets = +([player] call EFUNC(messaging,railNets));
{
    if !(_x isEqualType createHashMap) then {continue};
    private _box = _x getOrDefault ["boxId", ""];
    if (_box isEqualType "" && {(_box select [0, 2]) == "B:"}) then {
        _nets pushBackUnique (_box select [2]);
    };
} forEach _index;
_nets pushBack "ALL";

private _netH = _rowH * 1.25;
private _codeW = _railW * 0.2;

{
    private _net = _x;
    private _on = _net == GVAR(readerNet);
    private _ny = _rowY + _forEachIndex * _netH;

    private _unread = 0;
    {
        if (_x isEqualType createHashMap) then {
            if (_net == "ALL"
                || {(_x getOrDefault ["boxId", ""]) in [format ["B:%1", _net], format ["G:%1", _net]]}
                || {_net == "SQUAD" && {(_x getOrDefault ["boxId", ""]) == _squadBox}}) then {
                _unread = _unread + (_x getOrDefault ["unread", 0]);
            };
        };
    } forEach _index;

    if (_on) then {
        [_root, [0, _ny, _railW, _netH], _accent] call FUNC(drawFill);
    };

    // The design's three-letter net code, then the name. A net whose name is
    // already three letters or fewer prints once - "HQ HQ" read as a fault.
    private _code = toUpper (_net select [0, 3]);
    if (_code isNotEqualTo toUpper _net) then {
        [_root, [_side, _ny, _codeW, _netH], _code, [_muted, _ground] select _on, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    };
    [_root, [_side + _codeW, _ny, _railW * 0.55, _netH], _net, [_ink, _ground] select _on, READER_NET_SIZE, _on] call FUNC(drawText);

    if (_unread > 0) then {
        [_root, [_railW * 0.78, _ny, _railW * 0.22 - _side, _netH], str _unread, [_accent, _ground] select _on, READER_K_SIZE, true, "right"] call FUNC(drawText);
    };

    // THE RAIL IS THE ADDRESSEE SELECTOR WHILE A MESSAGE IS OPEN - harvest
    // first, because the redraw throws every edit away; and a reply does not
    // retarget, because its addressees belong to the thread.
    private _hit = [_root, [0, _ny, _railW, _netH], {
        params ["_ctrl"];
        private _pressed = _ctrl getVariable [QGVAR(net), "ALL"];

        if (GVAR(composeOn)) then {
            [] call FUNC(composeHarvest);
            if (GVAR(composeThread) isEqualTo "") then {
                GVAR(composeTo) = [_pressed, true] call FUNC(netBox);
                GVAR(composeToPick) = false;
            };
        } else {
            GVAR(readerThread) = "";
        };

        GVAR(readerNet) = _pressed;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(net), _net];
} forEach _nets;

_rowY = _rowY + (count _nets) * _netH + _padY * 2;
[_root, [0, _rowY, _railW, _ruleH], _dim] call FUNC(drawFill);
_rowY = _rowY + _ruleH + READER_INSET * _padY;

// ---------------------------------------------------------------- self ----
// Pinned to the foot: an initials square, then rank and name over role and squad.
private _selfH = _rowH * 2.2;
private _selfTop = _h - _selfH;
[_root, [0, _selfTop, _railW, _ruleH], _dim] call FUNC(drawFill);

private _tileH = _rowH * 1.4;
private _tileW = _tileH / pixelH * pixelW;
private _tileY = _selfTop + (_selfH - _tileH) * 0.5;
private _initials = ((((name player) splitString " ") apply {_x select [0, 1]}) joinString "") select [0, 2];

[_root, [_side, _tileY, _tileW, _tileH], _ink] call FUNC(drawFill);
[_root, [_side, _tileY, _tileW, _tileH], toUpper _initials, _ground, READER_K_SIZE, true, "center"] call FUNC(drawText);

private _nameX = _side + _tileW + _pad * 2;
private _nameW = _railW - _nameX - _side;
[
    _root, [_nameX, _tileY, _nameW, _tileH * 0.55],
    format ["%1 %2", [rank player] call FUNC(rankShort), name player], _ink, READER_ROSTER_SIZE, true
] call FUNC(drawText);
[
    _root, [_nameX, _tileY + _tileH * 0.55, _nameW, _tileH * 0.45],
    format ["%1 - %2", [player] call FUNC(roleShort), groupId (group player)], _muted, READER_K_SIZE, true, "left", true
] call FUNC(drawText);

// --------------------------------------------------------------- on net ---
// EVERY PLAYER, UNDER THEIR OWN SQUAD, own squad first and the rest
// alphabetical; a press on a squad head folds it, remembered in
// GVAR(readerNetFold). Rows stop above the self block rather than run under it.
private _fold = uiNamespace getVariable [QGVAR(readerNetFold), []];
private _mySquad = groupId (group player);

private _bySquad = createHashMap;
{
    private _sq = groupId (group _x);
    (_bySquad getOrDefault [_sq, [], true]) pushBack _x;
} forEach (allPlayers select {!isNull _x});

private _order = (keys _bySquad) - [_mySquad];
_order sort true;
if (_mySquad in keys _bySquad) then {_order = [_mySquad] + _order};

[_root, [_side, _rowY, _innerW, _rowH * 0.8], format ["ON NET - %1", count allPlayers], _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
_rowY = _rowY + _rowH;

private _lineH = _rowH * 0.95;
private _floor = _selfTop - _lineH;
private _markW = READER_MARK_PX * pixelW;
private _markH = READER_MARK_PX * pixelH;

{
    if (_rowY > _floor) exitWith {};

    private _sq = _x;
    private _men = _bySquad getOrDefault [_sq, []];
    private _open = !(_sq in _fold);
    private _up = {alive _x} count _men;

    [_root, [_side, _rowY, _railW * 0.1, _lineH], ["+", "-"] select _open, _muted, READER_K_SIZE, true] call FUNC(drawText);
    [
        _root, [_side + _railW * 0.1, _rowY, _railW * 0.55, _lineH], toUpper _sq,
        [_muted, _ink] select (_sq isEqualTo _mySquad), READER_K_SIZE, true, "left", true
    ] call FUNC(drawText);
    [_root, [_railW * 0.7, _rowY, _railW * 0.3 - _side, _lineH], format ["%1/%2", _up, count _men], _muted, READER_K_SIZE, true, "right", true] call FUNC(drawText);

    private _hit = [_root, [0, _rowY, _railW, _lineH], {
        params ["_ctrl"];
        private _sq = _ctrl getVariable [QGVAR(squad), ""];
        private _fold = uiNamespace getVariable [QGVAR(readerNetFold), []];
        if (_sq in _fold) then {_fold = _fold - [_sq]} else {_fold pushBack _sq};
        uiNamespace setVariable [QGVAR(readerNetFold), _fold];
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(squad), _sq];
    _rowY = _rowY + _lineH;

    if (_open) then {
        {
            if (_rowY > _floor) exitWith {};

            // Filled ink = up; an outline and the dim tone = down.
            private _alive = alive _x;
            private _markY = _rowY + (_lineH - _markH) * 0.5;
            if (_alive) then {
                [_root, [_side, _markY, _markW, _markH], _ink] call FUNC(drawFill);
            } else {
                [_root, [_side, _markY, _markW, _markH], _dim, RULE_THIN] call FUNC(drawFrame);
            };
            [_root, [_side + _markW + _pad * 2, _rowY, _railW * 0.55, _lineH], name _x, [_dim, _ink] select _alive, READER_ROSTER_SIZE] call FUNC(drawText);
            [_root, [_railW * 0.65, _rowY, _railW * 0.35 - _side, _lineH], [_x] call FUNC(roleShort), _muted, READER_K_SIZE, true, "right", true] call FUNC(drawText);
            _rowY = _rowY + _lineH;
        } forEach _men;
    };
} forEach _order;
