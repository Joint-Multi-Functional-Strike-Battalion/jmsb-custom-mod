#include "script_component.hpp"
/*
 * Author: JMSB
 * The one-tap reply tiles at the head of the reply picker - the handoff's 1b:
 * ROGER, WILCO and ON TASK, a reply with no fields, sent on the one press.
 *
 * A TILE SAYS WHAT THE PRESS DOES before it is pressed: ONE TAP - NO FIELDS,
 * the move it makes (the states it is legal from, and the state it leaves the
 * thread in), and who may send it. All three are read off the template - its
 * allowedFrom, transitionsTo and senderMustBe - so the tile cannot disagree
 * with the server that will judge it.
 *
 * Arguments:
 * 0: Group the picker is drawn into <CONTROL>
 * 1: Tiles, as [template id, template] pairs <ARRAY>
 * 2: Width available <NUMBER>
 *
 * Return Value:
 * Height used, gap under the row(s) included <NUMBER>
 *
 * Example:
 * private _h = [_body, _tiles, _w] call jmfsb_tacpad_fnc_composeTiles
 *
 * Public: No
 */

#define TILES_PER_ROW 3

params [
    ["_body", controlNull, [controlNull]],
    ["_tiles", [], [[]]],
    ["_w", 0, [0]]
];

if (isNull _body || {_tiles isEqualTo []}) exitWith {0};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _muted = ["muted"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;

private _tileW = (_w - _pad * (TILES_PER_ROW - 1)) / TILES_PER_ROW;
private _headH = _rowH * 1.1;
private _factH = _rowH * 0.62;
private _tileH = _headH + RULE_THICK * pixelH + 3 * _factH + 2 * _padY;
private _tagH = ([CARD_TAG_SIZE] call FUNC(textH)) + _padY;
private _glyph = ([CARD_TAG_SIZE] call FUNC(textH)) / 1.25 * CARD_GLYPH_W * pixelW / pixelH;

{
    _x params ["_id", "_t"];

    private _tx = (_forEachIndex % TILES_PER_ROW) * (_tileW + _pad);
    private _ty = floor (_forEachIndex / TILES_PER_ROW) * (_tileH + _pad);
    private _high = (_t getOrDefault ["priority", "normal"]) isEqualTo CARD_PRIORITY_HIGH;

    [_body, [_tx, _ty, _tileW, _tileH], _ink, RULE_THICK] call FUNC(drawFrame);

    // ------------------------------------------------------------ header ---
    private _short = toUpper (_t getOrDefault ["short", _id]);
    private _tagW = ((count _short) * _glyph + 2 * _pad) min (_tileW * CARD_TAG_MAX_W * 2);
    private _tagY = _ty + (_headH - _tagH) * 0.5;
    [_body, [_tx + _pad * 2, _tagY, _tagW, _tagH], [_ink, _accent] select _high] call FUNC(drawFill);
    [_body, [_tx + _pad * 2, _tagY, _tagW, _tagH], _short, _ground, CARD_TAG_SIZE, true, "center"] call FUNC(drawText);
    [
        _body, [_tx + _pad * 3 + _tagW, _ty, _tileW - _tagW - _pad * 5, _headH],
        toUpper (_t getOrDefault ["title", _id]), _ink, CARD_TITLE_SIZE, true
    ] call FUNC(drawText);
    [_body, [_tx + _pad, _ty + _headH, _tileW - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);

    // ------------------------------------------------------------- facts ---
    private _fy = _ty + _headH + RULE_THICK * pixelH + _padY;
    private _from = (_t getOrDefault ["allowedFrom", []]) joinString " / ";
    private _to = _t getOrDefault ["transitionsTo", ""];
    private _move = switch (true) do {
        case (_from isNotEqualTo "" && _to isNotEqualTo ""): {format ["%1 - %2", _from, _to]};
        case (_to isNotEqualTo ""): {format ["TO %1", _to]};
        default {_from};
    };
    private _mustBe = _t getOrDefault ["senderMustBe", "any"];
    private _who = ["ANY RECIPIENT", format ["%1 ONLY", toUpper _mustBe]] select (_mustBe in ["issuer", "assignee", "leader"]);

    [_body, [_tx + _pad * 2, _fy, _tileW - _pad * 4, _factH], "ONE TAP - NO FIELDS", _muted, CARD_BADGE_SIZE, true] call FUNC(drawText);
    [_body, [_tx + _pad * 2, _fy + _factH, _tileW - _pad * 4, _factH], _move, _ink, CARD_BADGE_SIZE, true] call FUNC(drawText);
    [_body, [_tx + _pad * 2, _fy + 2 * _factH, _tileW - _pad * 4, _factH], _who, _muted, CARD_BADGE_SIZE, true] call FUNC(drawText);

    // ------------------------------------------------------------- press ---
    // Straight to SEND. FUNC(composeSend) is the same path a filled card
    // takes, so a refusal lands beside SEND with the reason, as any other.
    private _hit = [_body, [_tx, _ty, _tileW, _tileH], {
        params ["_ctrl"];
        GVAR(composeTemplate) = _ctrl getVariable [QGVAR(pick), ""];
        GVAR(composePick) = false;
        GVAR(composeMarker) = "";
        [] call FUNC(composeSend);
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(pick), _id];
} forEach _tiles;

private _rows = ceil ((count _tiles) / TILES_PER_ROW);
_rows * (_tileH + _pad) + _padY
